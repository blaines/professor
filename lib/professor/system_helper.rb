require 'colorize'

module Professor
  class SystemHelper
    class << self
      def print_exec(cmd, color = :default)
        return show_exec(cmd, color).print(color)
      end

      def show_exec(cmd, color = :default)
        unless color == :default
          puts cmd.send(color)
        else
          puts cmd
        end
        return exec(cmd)
      end

      def exec(cmd)
        out_object = new(cmd).run
        raise "command ended with a non-zero exit status." if out_object.exitstatus != 0
        return out_object
      end
    end

    attr_reader :stdout, :exitstatus, :process

    def initialize(cmd)
      @command = cmd
      self
    end

    def print(color = :default)
      unless color == :default
        puts @stdout.send(color)
      else
        puts @stdout
      end
      self
    end

    def run
      @stdout = `#{@command} 2>&1`
      @exitstatus = $?.exitstatus
      @process = $?
      self
    end

  end
end