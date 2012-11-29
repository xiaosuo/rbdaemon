
require 'test/unit'
require 'rbdaemon/pidfile'

class TC_PidFile < Test::Unit::TestCase
  def test_smoke
    assert_equal(0, Process.uid)
    path = "/var/run/#{File.basename($0).split(/\./)[0]}.pid"
    pid_file = RBDaemon::PidFile.new
    assert(File.exist?(path))
    assert_equal($$, IO.read(path).rstrip.to_i)
    assert_raise(RBDaemon::PidFileError){RBDaemon::PidFile.new}
    pid_file.delete
    assert_equal(false, File.exist?(path))
  end
end
