require 'spec_helper'
require 'professor/cane/ruby_best_practices'

module Professor

  describe RubyBestPractices do

    def check(file_name, opts = {})
      described_class.new(opts.merge(rbp_glob: file_name))
    end

    it "creates a StyleViolation for each usage of puts or print" do
      file_name = make_file(<<-RUBY)
      puts "test"
      print "testing"
      printing_paper = true
      we_puts_it_down = false
      def putsit
      end
      RUBY

      violations = check(file_name).violations
      violations.length.should == 2
    end

    it "creates a StyleViolation for each usage of rescue Exception" do
      file_name = make_file(<<-RUBY)
      begin
      rescue Exception => e
      rescue Exception
      rescue ExceptionalException => e
      end
      RUBY

      violations = check(file_name).violations
      violations.length.should == 2
    end

    it "creates a StyleViolation for each usage of class (@@) variables" do
      file_name = make_file(<<-RUBY)
      @@please_dont_do_this = true
      RUBY

      violations = check(file_name).violations
      violations.length.should == 1
    end

    it "creates a StyleViolation for each usage of Rails.env" do
      file_name = make_file(<<-RUBY)
      Rails.env.development?
      Rails.env.test do
        run some code here
      end
      do_something_badly if Rails.env.production
      RUBY

      violations = check(file_name).violations
      violations.length.should == 3
    end

    it "creates a StyleViolation for each usage of sleep" do
      file_name = make_file(<<-RUBY)
      sleep(0x55444534)
      sleep 0x55444534
      sleep( never )
      RUBY

      violations = check(file_name).violations
      violations.length.should == 3
    end

    it "creates a StyleViolation for each usage of debugger" do
      file_name = make_file(<<-RUBY)
      debugger
      hidden debugger inline
      binding.pry
      RUBY

      violations = check(file_name).violations
      violations.length.should == 3
    end

    it "creates a StyleViolation for using {...} for multi-line blocks" do
      file_name = make_file(<<-RUBY)
      why_would_you {
        do_like_this?
      }
      somehash = {
        is: okay,
        :is => okay
      }
      def a_hash
        {
          lets: do,
          :this => okay
        }
      end
      you_really_shouldnt {
        do_this
      }.and_this
      RUBY

      violations = check(file_name).violations
      violations.length.should == 2
    end

    it "creates a StyleViolation for chaining do...end" do
      file_name = make_file(<<-RUBY)
      dont do
        this
      end.and_this
      RUBY

      violations = check(file_name).violations
      violations.length.should == 1
    end

    it "creates a StyleViolation for lack of spaces around the = operator when assigning default values to method parameters" do
      file_name = make_file(<<-RUBY)
      def method_name(and_arg=bad)
      end
      RUBY

      violations = check(file_name).violations
      violations.length.should == 1
    end

    it "creates a StyleViolation for using ||= to initialize boolean variables" do
      file_name = make_file(<<-RUBY)
      this_wontwork = false
      this_wontwork ||= true
      RUBY

      violations = check(file_name).violations
      violations.length.should == 1
    end

    it "creates a StyleViolation for using special variables (like $0-9, $, etc. )" do
      file_name = make_file(<<-RUBY)
      $!\n$"\n$$\n$&\n$&\n$'\n$'\n$*\n$+\n$+\n$,\n$-0\n$-a\n$-d\n$-F\n$-i\n$-I\n$-K\n$-l\n$-p\n$-v\n$-w\n$.\n$/\n$0\n$1\n$2\n$3\n$4\n$5\n$6\n$7\n$8\n$9\n$:\n$;\n$<\n$=\n$>\n$?\n$@\n$\\n$_\n$`
      $binding\n$DEBUG\n$deferr\n$defout\n$FILENAME\n$KCODE\n$LOAD_PATH\n$LOADED_FEATURES\n$PROGRAM_NAME\n$SAFE\n$stderr\n$stdin\n$stdout\n$VERBOSE\n$~
      RUBY

      violations = check(file_name).violations
      violations.length.should == 57
    end

    it "creates a StyleViolation for nested ternary operators" do
      file_name = make_file(<<-RUBY)
      what ? does : this ? even : mean
      RUBY

      violations = check(file_name).violations
      violations.length.should == 1
    end

    it "creates a StyleViolation for using then for multi-line if/unless" do
      file_name = make_file(<<-RUBY)
      if you_do_this then
        exit(1)
      end
      unless youre_smarter then
        the_robot
      end
      RUBY

      violations = check(file_name).violations
      violations.length.should == 2
    end

    it "creates a StyleViolation for methods defined without arguments with parentheses" do
      file_name = make_file(<<-RUBY)
        def bad_example()
        end
      RUBY

      violations = check(file_name).violations
      violations.length.should == 1
    end

  end
end