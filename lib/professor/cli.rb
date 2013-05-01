require 'professor/version'
require 'thor'
require 'professor'
require 'cane'

module Professor
  class CLI < Thor
    include Thor::Actions

    desc "help", "help"
    def help
      puts "# Professor"
      puts "* grade [everything, changes, commit] - Default: grade changes or last commit"
      puts "* automate - sets up professor to run automatically with a pre-commit hook"
    end

    desc "grade", "grade"
    def grade(what_to_grade = nil)
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

    desc "automate", "automate"
    method_options :force => :boolean
    def automate
      if options.force? || yes?("This will install Professor to the global gemset and add a pre-commit hook, okay?".yellow)
        puts "*  RVM is installed".green if SystemHelper.show_exec("which rvm").exitstatus == 0
        rubies = SystemHelper.show_exec("rvm list strings").stdout
        selected_ruby ||= rubies[/1\.9\.3/]
        selected_ruby ||= rubies[/1\.9\.2/]
        puts "*  Professor will use Ruby #{selected_ruby}".green
        create_file ".git/hooks/pre-commit" do
          [
            "#!/bin/sh",
            "rvm #{selected_ruby} do professor pre-commit-plumbing"
          ].join("\n")
        end
        chmod ".git/hooks/pre-commit", 0766
        begin
          SystemHelper.show_exec("rvm #{selected_ruby} do professor version") == Professor::VERSION
          puts "*  Professor already installed!".green
          puts "=> Professor is automated! :)".green
        rescue
          SystemHelper.show_exec("rvm #{selected_ruby}@global do gem install professor")
          begin
            puts "* Installed professor to #{selected_ruby}@global".green if SystemHelper.show_exec("rvm #{selected_ruby}@global do gem install professor").exitstatus == 0
            puts "=> Professor is automated! :)".green
          rescue
            puts "You'll need to install Professor manually...".yellow
            puts "1. rvm use #{selected_ruby}@global"
            puts "2. Install professor gem (See installation at https://source.flexilis.local/gems/professor )"
          end
        end
      end
    end

    desc "schema-migration-plumbing", "schema_migration_plumbing"
    method_option :verbose, :aliases => "-v", :desc => "Verbose, duh."
    method_option :from, :aliases => "-f", :desc => "Starting commit to verify"
    method_option :to, :aliases => "-t", :desc => "Last commit to verify"
    method_option :cwd, :aliases => "-c", :desc => "Verify current working directory"
    def schema_migration_plumbing
      options[:delete]
      start_cset = options[:from]
      end_cset = options[:to]
      working_dir = options[:cwd]

      # Get start/end changesets from Jenkins job environment.
      # Use Head/Parent-of-Head if Jenkins environment not found (for testing)
      start_cset ||= ENV.has_key?("GIT_PREVIOUS_COMMIT") ? ENV["GIT_PREVIOUS_COMMIT"] : "HEAD^1"
      end_cset ||= ENV.has_key?("GIT_CURRENT_COMMIT") ? ENV["GIT_CURRENT_COMMIT"] : "HEAD"
      working_dir ||= Dir.pwd

      if options[:verbose]
        git = ::Git.open(working_dir, :log => Logger.new(STDOUT))
      else
        git = ::Git.open(working_dir)
      end

      check = Git::CommitCheckRange.new(git, start_cset, end_cset)

      # Check for violations. Exit with 1 if violations are found.
      result = check.has_migrations_without_schema_update?
      exit(result ? 1 : 0)
    end

    desc "pre-commit", "pre_commit"
    def pre_commit
      unless grade
        puts "Please fix the violations before committing.".red
        exit(1)
      end
    end

    desc "post-commit", "post_commit"
    def post_commit
      unless grade
        puts "Please fix the violations.".red
        exit(1)
      end
    end

    desc "version", "version"
    def version
      puts Professor::VERSION
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