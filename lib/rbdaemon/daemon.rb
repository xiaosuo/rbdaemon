
require 'rbdaemon/conventions'
require 'rbdaemon/pidfile'
require 'etc'
require 'syslog'

module RBDaemon
  class DaemonError < StandardError; end

  class Daemon
    def initialize(options = {}, *args)
      exit!(0) if fork
      Process.setsid
      Signal.trap('HUP'){}
      exit!(0) if fork

      options[:no_change_umask] or File.umask(RBDaemon::UMASK)

      unless options[:no_close]
        ObjectSpace.each_object(IO) do |io|
          [STDIN, STDOUT, STDERR].include?(io) and next
          io.closed? or io.close rescue nil
        end
        STDIN.reopen(RBDaemon::STDIO_PATH)
        STDOUT.reopen(RBDaemon::STDIO_PATH, 'w')
        STDERR.reopen(RBDaemon::STDIO_PATH, 'w')
      end

      @pid_file = PidFile.new(options[:pid_file])

      unless options[:no_trap_term]
        Signal.trap('TERM') do
          exit(0)
        end
      end

      ident = options[:pid_file] ? options[:pid_file] : $0
      ident = File.basename(ident).split(/\./)[0]

      Signal.trap('EXIT') do
        Syslog::log(Syslog::LOG_INFO, "#{ident} exited")
        options[:change_root] or (@pid_file and @pid_file.delete) rescue nil
      end

      if options[:user]
        user = options[:user]
        options[:groups] ||= [user]
        uid = user.class == String ? Etc.getpwnam(user).uid : user
      end

      if options[:groups]
        groups = options[:groups].map do |group|
          case group
          when Fixnum
            group
          when String
            Etc.getgrnam(group).gid
          else
            raise ArgumentError, 'invalid group: ' + group
          end
        end
        if options[:user]
          groups.concat(Process.initgroups(options[:user], groups[0]))
        end
        if options[:user] and groups.include?(uid) 
          gid = uid
        else
          gid = groups[0]
        end
        Process::groups = groups.uniq
        Process::GID::change_privilege(gid)
      end

      Syslog::open(ident, Syslog::LOG_NDELAY | Syslog::LOG_PID,
                   Syslog::LOG_DAEMON)

      if options[:change_root]
        Dir.chdir(options[:change_root])
        Dir.chroot('.')
      elsif not options[:no_change_dir]
        Dir.chdir(RBDaemon::WORK_DIR)
      end

      Process::UID::change_privilege(uid) if options[:user]

      Syslog::log(Syslog::LOG_INFO, "#{ident} started")
      yield self, *args

      exit(0)
    end
  end
end
