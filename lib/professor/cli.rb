require 'professor/version'
require 'thor'
require 'professor'
require 'cane'

module Professor
  class CLI < Thor
    desc "help", "help"
    def help
      puts "Professor"
    end

    desc "exec", "exec"
    def exec
      puts "Professor running"
      spec = {
        :max_violations=>0,
        :parallel=>false,
        :exclusions_file=>nil,
        :checks=>[RubyBestPractices],
        :rbp_glob=>"{app,lib}/**/*.rb"
      }
      Cane.run(spec)
    end

    desc "grade", "grade"
    def grade
      comm = SystemHelper.show_exec("git diff-tree --no-commit-id --name-only -r HEAD")
      spec = {
        :max_violations=>0,
        :parallel=>false,
        :exclusions_file=>nil,
        :checks=>[RubyBestPractices],
        :rbp_glob=>comm.stdout.split.reject {|s| !(s =~ /\.rb/)}
      }
      Cane.run(spec)
    end
  end
end