require 'cane/file'
require 'cane/task_runner'

module Professor
  class Generic < Struct.new(:opts)
    def self.key; :generic; end
    def self.name; "generic name"; end
    def self.options
      {
        generic_glob:    ['Glob to run generic checks over',
                         variable:  'GLOB',
                         type:      Array,
                         default:   [],
                         clobber:   :no_generic],
        generic_exclude:  ['Exclude file or glob from generic checking',
                         variable:  'GLOB',
                         type:      Array,
                         default:   [],
                         clobber:   :no_generic],
        no_generic:      ['Disable generic checking', cast: ->(x) { !x }]
      }
    end

    def violations
      return [] if opts[:no_generic]

      result = worker.map(file_list) do |file_path|
        problems = []
        problems += map_lines(file_path) do |line, line_number|
          violations_for_line(line.chomp).map do |message|
            {
              file:        file_path,
              line:        line_number + 1,
              label:       message,
              description: "Lines violated requirements"
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
      rescue => e
        puts "Error processing line: #{line}"
        raise
      end
      result
    end

    def simple_violations(line)
      result = []
      result << "Avoid the usage of puts or print"                                                      if line =~ /^\s*p(uts|rint)?[\s\(]+(.+?)\s*[\)\s]*$/
      result
    end

    # Possibly set default to '{app,lib}/**/*.rb'
    def file_list
      list = opts.fetch(:generic_glob)
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
      @exclusions ||= opts.fetch(:generic_exclude, []).flatten.map do |i|
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