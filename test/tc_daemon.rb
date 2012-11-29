
require 'test/unit'
require 'rbdaemon/daemon'
require 'tempfile'

class TC_Daemon < Test::Unit::TestCase
  def test_smoke
    assert_equal(0, Process.uid)
    tmpfile = ::Tempfile.new('tc_daemon', '/tmp')
    File::chmod(0666, tmpfile.path)
    Process.fork do 
      RBDaemon::Daemon.new({:user => 'nobody', :groups => 'nobody',
                            :change_root => '/tmp'},
                           3, "ok\n", tmpfile.path) do |daemon, times, str, path|
        tmpfile = File.new(File.basename(path), 'w')
        times.times do
          tmpfile.write(str)
        end
        tmpfile.flush
        loop do
          sleep(3)
        end
      end
    end
    # let the daemon process run
    sleep(1)

    # check pid
    pid_file = "/var/run/#{File.basename($0).split(/\./)[0]}.pid"
    assert(File.exist?(pid_file))
    pid = IO.read(pid_file).rstrip.to_i
    assert_nothing_raised{Process::kill(0, pid)}
    proc_root = "/proc/#{pid}"
    status = {}
    IO.foreach("#{proc_root}/status") do |l|
      k, v = l.rstrip.split(/:\s*/)
      status[k] = v
    end
    assert_equal(pid, status['Pid'].to_i)

    stat = IO.read("#{proc_root}/stat").rstrip.split(/\s+/)
    assert_equal(pid, stat[0].to_i)
    # the current ppid should 1
    assert_equal(1, stat[3].to_i)
    # must not be the group leader
    assert_not_equal(pid, stat[4].to_i)
    # a different session id
    assert_not_equal(IO.read("/proc/self/stat").rstrip.split(/\s+/)[5], stat[5])
    # pgid == sid
    assert_equal(stat[4], stat[5])

    # check daemon's work
    lines = IO.readlines(tmpfile.path)
    assert_equal(3, lines.length)
    assert_equal("ok\n", lines[0])

    # check uid and gid
    uid = Etc.getpwnam('nobody').uid
    gid = Etc.getgrnam('nobody').gid
    status['Uid'].split(/\s+/).each do |s|
      assert_equal(uid, s.to_i)
    end
    status['Gid'].split(/\s+/).each do |s|
      assert_equal(gid, s.to_i)
    end

    # check fds
    Dir["#{proc_root}/fd/*"].each do |fn|
      fd = File.basename(fn).to_i
      assert((0..5).to_a.include?(fd))
      case fd
      when 0, 1, 2
        assert_equal('/dev/null', File::readlink(fn))
      when 3
        assert_equal(pid_file, File::readlink(fn))
      when 4
        assert_match(/socket:\[\d+\]/, File::readlink(fn))
      when 5
        assert_equal(tmpfile.path, File::readlink(fn))
      end
    end

    # check root directory
    assert_equal('/tmp', File::readlink("#{proc_root}/root"))
    assert_equal('/tmp', File::readlink("#{proc_root}/cwd"))

    # terminate daemon
    assert_nothing_raised{Process::kill('TERM', pid)}
    sleep(1)
    # check pid file
    assert(File.exist?(pid_file))
    assert_raise(Errno::ESRCH){Process::kill(0, pid)}
  end

  def test_normal_use
    assert_equal(0, Process.uid)
    Process.fork do
      RBDaemon::Daemon.new do
        loop{sleep(3)}
      end
    end
    sleep(1)
    pid_file = "/var/run/#{File.basename($0).split(/\./)[0]}.pid"
    assert(File.exist?(pid_file))
    pid = IO.read(pid_file).rstrip.to_i
    assert_nothing_raised{Process::kill(0, pid)}
    proc_root = "/proc/#{pid}"
    assert_equal('/', File::readlink("#{proc_root}/root"))
    assert_equal('/', File::readlink("#{proc_root}/cwd"))
    assert_nothing_raised{Process::kill('TERM', pid)}
    sleep(1)
    assert_equal(false, File.exist?(pid_file))
  end

  def test_non_root
    Process.uid == 0 and Process.euid = 1000
    pid_file = Tempfile.new('tc_daemon')
    Process.fork do
      RBDaemon::Daemon.new(:pid_file => pid_file.path) do
        loop{sleep(3)}
      end
    end
    sleep(1)
    pid = pid_file.read.rstrip.to_i
    assert_nothing_raised{Process::kill('TERM', pid)}
    sleep(1)
    assert_equal(false, File.exist?(pid_file.path))
    Process.uid == 0 and Process.euid = 0
  end
end