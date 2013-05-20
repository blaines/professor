# Professor::Interface::Git
require 'grit'
module Professor
  module Interface
    module Git
      class Repo

        def initialize
          @repo = Grit::Repo.new(".")
        end

        def rev_parse(rev)
          SystemHelper.exec("git rev-parse #{rev}")
        rescue
          return false
        end

        def diff_index
          SystemHelper.show_exec("git diff-index --name-only #{rev}").stdout
        rescue
          return false
        end

        def diff_tree
          SystemHelper.show_exec("git diff-tree --no-commit-id --name-only -r HEAD").stdout
        rescue
          return false
        end

        def parse_diff
          Diff.new(@repo)
        end

        def status
          SystemHelper.show_exec("git status --porcelain").stdout
        end

        def valid_rev?(rev)
          !!rev_parse(rev)
        end

      end

      class File
        attr_accessor :name, :chunks

        def initialize(name, text)
          @name = name
          @chunks = Chunk.process_text(text, self)
          self
        end

        def additions
          @chunks.map {|c| c.additions if c.has_additions?}.flatten.compact
        end

        def deletions
          @chunks.map {|c| c.deletions if c.has_deletions?}.flatten.compact
        end
      end

      class Chunk
        attr_accessor :lines, :start_line, :number_of_lines, :file

        def self.process_text(text, file)
          puts file.name
          chunks = text.split(/^@@\s.+\s@@.+\n/)[1..-1]
          ranges = text.scan(/^@@\s-(\d+),(\d+)\s\+(\d+),(\d+)\s@@/)
          chunks = chunks.zip(ranges).map {|a, b| {:text => a, :range => b}}
          diff_not_removed = chunks.map do |unprocessed_chunk|
            # Skip chunks with no changes
            next unless unprocessed_chunk[:text].scan(/^[\+\-].+/).size > 0
            chunk = new
            unprocessed_line_iter = 0
            # Only lines added
            lines = unprocessed_chunk[:text].scan(/^.+/).map do |unprocessed_line|
              if unprocessed_line[/^\+.+/]
                line = Line.new
                line.num = unprocessed_chunk[:range][2].to_i + unprocessed_line_iter
                unprocessed_line_iter+=1
                if unprocessed_line[/^\+.+/]
                  chunk.has_additions
                  line.is_addition
                end
               if unprocessed_line[/^\-.+/]
                  chunk.has_deletions
                  line.is_deletion
                end
                line.line = unprocessed_line[1..-1]
                line.chunk = chunk
                line
              elsif unprocessed_line[/\-.+/]
              else
                unprocessed_line_iter+=1
                next
              end
            end
            lines.compact!
            chunk.lines = lines
            chunk.file = file
            chunk.start_line = unprocessed_chunk[:range][2]
            chunk.number_of_lines = unprocessed_chunk[:range][3]
            chunk
          end
        end

        def additions
          @lines.map {|l| l if l.is_addition?}.compact
        end

        def deletions
          @lines.map {|l| l if l.is_deletion?}.compact
        end

        def has_additions
          @has_additions = true
        end

        def has_additions?
          @has_additions || false
        end

        def has_deletions
          @has_deletions = true
        end

        def has_deletions?
          @has_deletions || false
        end

      end

      class Line
        attr_accessor :num, :line, :chunk
        def initialize(num = nil, line = nil, chunk = nil)
          @num, @line, @chunk = num, line, chunk
        end

        def to_s
          "#<#{self.class}> #{num} #{@line.slice(0,20)}..."
        end

        def file
          chunk.file
        end

        def is_addition
          @is_addition = true
        end

        def is_addition?
          @is_addition || false
        end

        def is_deletion
          @is_deletion = true
        end

        def is_deletion?
          @is_deletion || false
        end
      end

      class Diff
        def self.diffit(repo)
          diff_array = Grit::Diff.list_from_string(repo, `git diff HEAD~3`)
          diff_array.map! do |instance|
            File.new(instance.b_path, instance.diff)
          end
          diff_array
        end
      end
    end
  end
end

repo = Professor::Interface::Git::Repo.new
d = Professor::Interface::Git::Diff.diffit repo
puts d.map(&:additions).flatten.map(&:line)

# Diff::File
# Diff::Chunk
# Diff::Line



#       def valid_rev?(rev)
#       end

#       def git_diff_index(rev)
#         changed_files = SystemHelper.show_exec("git diff-index --name-only #{rev}").stdout
#         changed_files.split.reject {|s| !(s =~ /\.rb/)}
#       end

#       def grade_everything
#         files_to_grade ||= "{app,lib}/**/*.rb"
#       end

#       def grade_changes
#         changed_files = SystemHelper.show_exec("git diff-index --name-only HEAD").stdout
#         files_to_grade ||= changed_files.split.reject {|s| !(s =~ /\.rb/)}
#       end

#       def grade_commit
#         changed_files = SystemHelper.show_exec("git diff-tree --no-commit-id --name-only -r HEAD").stdout
#         files_to_grade ||= changed_files.split.reject {|s| !(s =~ /\.rb/)}
#       end

#       def grade_porcelain
#         if SystemHelper.show_exec("git status --porcelain").stdout.empty?
#           grade_commit
#         else
#           grade_changes
#         end
#       end