
require 'rbdaemon/conventions'

module RBDaemon
  class PidFileError < StandardError; end

  class PidFile
    def initialize(pid_file = nil)
      if pid_file
        @path = pid_file
      else
        program = File.basename($0).split(/\./)[0]
        @path = File.join(RBDaemon::PID_FILE_DIR, program + '.pid')
      end
      @file = File.new(@path, File::WRONLY | File::CREAT, 0644)
      unless @file.flock(File::LOCK_NB | File::LOCK_EX)
        raise PidFileError, 'failed to lock ' + @path
      end
      @file.truncate(0)
      @file.write("#{$$}\n")
      @file.flush
    end

    def delete
      File.delete(@path)
    end
  end
end
