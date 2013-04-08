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

    desc "grade", "grade"
    def grade(what_to_grade=nil)
      case what_to_grade
      when /everything/i
        files_to_grade = grade_everything
      when /changes/i
        files_to_grade = grade_changes
      when /commit/i
        files_to_grade = grade_commit
      when nil
        files_to_grade = grade_porcelain
      end
      spec = {
        :max_violations=>0,
        :parallel=>false,
        :exclusions_file=>nil,
        :checks=>[RubyBestPractices],
        :rbp_glob=>files_to_grade
      }
      Cane.run(spec)
    end

    no_tasks do
      def grade_everything
        files_to_grade ||= "{app,lib}/**/*.rb"
      end

      def grade_changes
        changed_files = SystemHelper.show_exec("git diff-index --name-only HEAD").stdout
        files_to_grade ||= changed_files.split.reject {|s| !(s =~ /\.rb/)}
      end

      def grade_commit
        changed_files = SystemHelper.show_exec("git diff-tree --no-commit-id --name-only -r HEAD").stdout
        files_to_grade ||= changed_files.split.reject {|s| !(s =~ /\.rb/)}
      end

      def grade_porcelain
        if SystemHelper.show_exec("git status --porcelain").stdout.empty?
          grade_commit
        else
          grade_changes
        end
      end
    end
  end
end