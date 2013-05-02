require 'professor/version'
require 'thor'
require 'professor'
require 'cane'

module Professor
  class CLI < Thor
    include Thor::Actions
    class << self

      def all_verifiers
        self.instance_methods.map {|z| $1 if z[/check_(.+)/]}.compact!
      end

    end
    default_task :grade

    # desc "help", "help"
    # def help
    #   puts "# Professor"
    #   puts "* grade [everything, changes, commit] - Default: grade changes or last commit"
    #   puts "* automate - sets up professor to run automatically with a pre-commit hook"
    # end
    # git commit -a --amend
    # git diff
    # git merge

    # ALL           ls files
    # untracked     -
    # unmodified    -
    # modified      git diff
    # staged        git diff --cached HEAD
    # SHAs          git diff <commit> <commit>
    # method_option :everything,  :aliases => "-a", :desc => "Checks the entire project"
    # method_option :staged,      :aliases => "-m", :desc => "Checks staged changes"
    # method_option :modified,    :aliases => "-s", :desc => "Checks all changes"
    # method_option :staged,      :aliases => "-", :desc => "Checks staged changes"
    # grade where
    # check what where
    # check-practices where
    # check-schema where
    # check-jira where
    # check-tests
    # Grade runs all checks
    # def grade(what_to_grade = nil)
    #   schema-migration-plumbing
    #   case what_to_grade
    #   when /everything/i
    #     files_to_grade = grade_everything
    #   when /changes/i
    #     files_to_grade = grade_changes
    #   when /commit/i
    #     files_to_grade = grade_commit
    #   when nil
    #     files_to_grade = grade_porcelain
    #   end
    # end

    desc "check-style", "check_style"
    def check_style(*args)
      before_checks(args)
      spec = {
        :max_violations   => 0,
        :parallel         => false,
        :exclusions_file  => nil,
        :checks           => [RubyBestPractices],
        :rbp_glob         => @@selected_files
      }
      Cane.run(spec)
      invoke :exec_checks, args
    end
    map :practices => :check_style

    desc "check-schema", "check_schema"
    def check_schema(*args)
      before_checks(args)
      schema_migration_plumbing
      invoke :exec_checks, args
    end

    desc "grade [<command>...] [<commit>]", ["Verify all changes since <commit> using <command>",
      "Possible options are: #{(self.all_verifiers).join(",\s")}"].join("\n")
    def grade(*args)
      before_checks(args)
      args = self.all_verifiers if args.empty?
      invoke :exec_checks, args
    end
    map :check => :grade

    desc "exec-checks", "exec_checks"
    def exec_checks(*args)
      args.each do |arg|
        invoke "check_#{arg}".intern
      end
    end

    desc "automate", "Adds a git pre-commit hook to automatically verify changes"
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
      def before_checks(args)
        # has_git?
        process_what_to_grade(args)
        # z = self.class.instance_methods.map {|z| $1 if z[/check_(.+)/]}.compact!
        # args.each do |arg|
        #   puts "No check found for #{arg}!"
        # end
        # puts z.inspect
      end

      # We need to figure out how to seperate actions from git revs
      def process_what_to_grade(args)
        return @@selected_files if defined? @@selected_files
        # Probably a bad way to get two possible revs, say to compare <from rev> <to rev>
        # possible_revs = []
        # if possible_revs[0] = args[-2]
        #   possible_revs[1] = args[-1]
        # else
        #   possible_revs[0] ||= args[-1]
        # end
        #
        # Verify each are valid git revs
        # possible_revs.map! do |opt|
        #   begin
        #     SystemHelper.exec("git rev-parse #{opt}")
        #     opt
        #   rescue
        #     puts "#{opt} is not a ref"
        #   end
        # end
        #
        # possible_revs.compact!

        rev = args.last
        if valid_rev?(rev)
          @@rev = rev
          args.pop
        end
        @@rev ||= "HEAD"
        @@selected_files ||= git_diff_index(@@rev)
        @@selected_files
      end

      def valid_rev?(rev)
        begin
          SystemHelper.exec("git rev-parse #{rev}")
          return true
        rescue
          return false
        end
      end

      def git_diff_index(rev)
        changed_files = SystemHelper.show_exec("git diff-index --name-only #{rev}").stdout
        changed_files.split.reject {|s| !(s =~ /\.rb/)}
      end

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