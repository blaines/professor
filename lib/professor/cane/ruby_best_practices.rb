require 'cane/file'
require 'cane/task_runner'

module Professor
  class RubyBestPractices < Struct.new(:opts)
    ACCEPTABLE_CLASS_ACRONYMS = %w(HTTP RFC XML URI)

    def self.key; :rbp; end
    def self.name; "ruby best practices"; end
    def self.options
      {
        rbp_glob:    ['Glob to run rbp checks over',
                         variable:  'GLOB',
                         type:      Array,
                         default:   [],
                         clobber:   :no_rbp],
        rbp_exclude:  ['Exclude file or glob from rbp checking',
                         variable:  'GLOB',
                         type:      Array,
                         default:   [],
                         clobber:   :no_rbp],
        no_rbp:      ['Disable rbp checking', cast: ->(x) { !x }]
      }
    end

    def violations
      return [] if opts[:no_rbp]

      result = worker.map(file_list) do |file_path|
        problems = []
        if file_path =~ /billing_mechanism(\.rb|_)/i && !(file_path =~ /^test/i)
          problems += map_lines(file_path) do |line, line_number|
            violations_for_billing_mechanisms(line.chomp).map do |message|
              {
                file:        file_path,
                line:        line_number + 1,
                label:       message,
                description: "Lines violated style requirements"
              }
            end
          end
        end
        problems += map_lines(file_path) do |line, line_number|
          violations_for_line(line.chomp).map do |message|
            {
              file:        file_path,
              line:        line_number + 1,
              label:       message,
              description: "Lines violated style requirements"
            }
          end
        end
      end
      result.flatten
    end

    protected

    def violations_for_line(line)
      begin
        result = []
        result += simple_violations(line)
        # result += violations_for_class_name(line) # WIP
        result += violations_for_method_name(line)
      rescue => e
        puts "Error processing line: #{line}"
        raise
      end
      result
    end

    def simple_violations(line)
      result = []
      result << "Avoid the usage of puts or print"                                                      if line =~ /^\s*p(uts|rint)?[\s\(]+(.+?)\s*[\)\s]*$/
      result << "Avoid rescuing Exception, try StandardError instead"                                   if line =~ /rescue.Exception(\W|$)/i
      result << "Avoid the usage of class (@@) variables"                                               if line =~ /@@(\w+)/i
      result << "Avoid the usage of Rails.env.#{$1}"                                                    if line =~ /Rails\.env\.(\w+)/i
      result << "Somebody seriously used sleep"                                                         if line =~ /sleep[\s(]+\w+/i
      result << "There's a debugger here"                                                               if line =~ /(debugger|binding\.pry)/i
      result << "Avoid using {...} for multi-line blocks. Use do...end"                                 if line =~ /[^=>\s\(\{\<]\s?\{(\s+\|\w+\|\s*)?$/i
      result << "Avoid do...end when chaining"                                                          if line =~ /end\.\w/i
      result << "Use spaces around the = operator when assigning default values to method parameters"   if line =~ /def\s[^\s(]+(,?[\s(]\w+=[^,\s]+)+/i
      result << "Don't use ||= to initialize boolean variables"                                         if line =~ /\w+\s?\|\|\= true/i
      # result << "Never put a space between a method name and the opening parenthesis"                 if line =~ /^(?![^#]+(if|elsif|unless|=))[^#]+\s\([^)]+\)/i\

      # This needs to be modified as there are sometimes no alternatives to special vars (ruby1.8/regex)
      # result << "Avoid using Perl-style special variables (like $0-9, $, etc. )"                        if line =~ /^[^\/]*\$[\w\!\"\&\'\*\+\,\-\.\/\:\;\<\=\>\?\@\\\_\`\~]+/

      result << "Use one expression per branch and nested don't nest ternary operators"                 if line =~ /\s\?.+:\s.+\s\?.+:\s/i
      result << "Never use then for multi-line if/unless"                                               if line =~ /^[^#]*(if|unless)[\s\(]{1,2}[^\)\s]+[\)\s]{1,2}then/i
      # Use def with parentheses when there are arguments. Omit the parentheses when the method doesn't accept any arguments.
      result << "Remove parentheses from methods defined without arguments"                             if line =~ /def\s[^\s\(]+\(\)/i
      result
    end

    # WIP
    def violations_for_class_name(line)
      # Break up each capitalized word
      result = []
      if line =~ /^\s*(class|module) \w+/i
        matches = line.match(/^\s*(class|module)\s([\w]+)+(\s<\s([\w:]+)+)?/)
        class_name = matches[2]
        class_name_parts = class_name.split(/(?<!^|[A-Z])(?=[A-Z])|(?<!^)(?=[A-Z][a-z])/)
        puts class_name_parts.inspect
        # class_names ||= [matches[2]]
        # class_names << matches[4] if matches[4]
        # puts class_names.inspect
        # class_names.each
        # class_name_words = class_name.split(/(?<!^|[A-Z])(?=[A-Z])|(?<!^)(?=[A-Z][a-z])/)
        # unless class_names.all? {|name| name[/(([A-Z][a-z0-9]+|::))+/] == name || !!ACCEPTABLE_CLASS_ACRONYMS.index(name)}
        #   result << "Use CamelCase for classes and modules. (Keep acronyms like HTTP, RFC, XML uppercase.)"
        #   result << class_names.inspect
        # end
      end
      result
    end

    def violations_for_method_name(line)
      result = []
      if line =~ /^\s*def \w+/i
        matches = line.match(/^\s*def\s(\w+)/)
        method_name ||= matches[1]
        unless method_name == method_name[/^[a-z0-9_]+/]
          result << "Use snake_case for methods and variables. (method name #{method_name})"
        end
      end
      result
    end

    def violations_for_billing_mechanisms(line)
      result = []
      result << "Line defines an instance variable (in a singleton)" if line =~ /@(\w+)/i
      result
    end

    # def file_names
    #   Dir[opts.fetch(:rbp_glob, RBP_GLOB)].reject { |file| excluded?(file) }
    # end

    # Possibly set default to '{app,lib}/**/*.rb'
    def file_list
      list = opts.fetch(:rbp_glob)
      if list.class == Array
        list.map do |i|
          Dir[i].reject {|f| excluded?(f) }
        end
        return list.flatten
      else
        return Dir[list].reject {|f| excluded?(f) }
      end
    end

    def map_lines(file_path, &block)
      Cane::File.iterator(file_path).map.with_index(&block)
    end

    def exclusions
      @exclusions ||= opts.fetch(:rbp_exclude, []).flatten.map do |i|
        Dir[i]
      end.flatten.to_set
    end

    def excluded?(file)
      exclusions.include?(file)
    end

    def worker
      Cane.task_runner(opts)
    end
  end
end