require 'cane/file'
require 'cane/task_runner'

class RubyBestPractices < Struct.new(:opts)
  DESCRIPTION =
    "Ruby best practices"
  RBP_REGEX = /^\s*p(uts|rint)?[\s\(]+(.+?)\s*[\)\s]*$/
  RBP_GLOB = '{app,lib}/**/*.rb'

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
      if file_path =~ /billing_mechanism(\.rb|_)/i
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
    result = []
    result << "Avoid the usage of puts or print" if line =~ RBP_REGEX
    result << "Avoid rescuing Exception, try StandardError instead"                                   if line =~ /rescue.Exception/i
    result << "Avoid the usage of class (@@) variables"                                               if line =~ /@@(\w+)/i
    result << "Avoid the usage of Rails.env.#{$1}"                                                    if line =~ /Rails\.env\.(\w+)/i
    result << "Somebody seriously used sleep"                                                         if line =~ /sleep[\s(]\d+/i
    result << "There's a debugger here"                                                               if line =~ /(debugger|binding\.pry)/i
    result << "Avoid using {...} for multi-line blocks. Use do...end"                                 if line =~ /[^=>\s\(\{\<]\s?\{(\s+\|\w+\|\s*)?$/i
    result << "Avoid do...end when chaining"                                                          if line =~ /end\.\w/i
    result << "Use spaces around the = operator when assigning default values to method parameters"   if line =~ /def\s[^\s(]+(,?[\s(]\w+=[^,\s]+)+/i
    result << "Don't use ||= to initialize boolean variables"                                         if line =~ /\w+\s?\|\|\= true/i
    # result << "Never put a space between a method name and the opening parenthesis"                 if line =~ /^(?![^#]+(if|elsif|unless|=))[^#]+\s\([^)]+\)/i\
    result << "Avoid using Perl-style special variables (like $0-9, $, etc. )"                        if line =~ /(if|unless).+\n.+\nend/
    result << "Use one expression per branch and nested don't nest ternary operators"                 if line =~ /\s\?.+:\s.+\s\?.+:\s/i
    result << "Never use then for multi-line if/unless"                                               if line =~ /^[^#]*(if|unless)[\s\(]{1,2}[^\)\s]+[\)\s]{1,2}then/i
    # Use def with parentheses when there are arguments. Omit the parentheses when the method doesn't accept any arguments.
    result << "Remove parentheses from methods defined without arguments"                                  if line =~ /def\s[^\s\(]+\(\)/i
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

  def file_list
    list = opts.fetch(:rbp_glob, RBP_GLOB)
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