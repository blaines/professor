# Professor::Interface::Git
module Professor
  module Interface
    module Git
      class Repo
        class << self
        end

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

      class Diff
        class File
          def initialize

          end
        end
        class Chunk

        end
        class Line
        end

        def initialize(repo)
          diff_array = Grit::Diff.list_from_string(repo, `git diff HEAD`)
          diff_array.end do |instance|
            current_file_name = instance.b_path
            text = instance.diff
            File.new(current_file_name, text)

            chunks = text.split(/^@@\s.+\s@@.+\n/)
            text.scan(/^@@\s-(\d+),(\d+)\s\+(\d+),(\d+)\s@@/)
            # [["6", "37", "6", "95"], ["122", "6", "180", "63"]]
            # -<start line>,<number of lines> +<start line>,<number of lines>
            processed
          end
        end
      end
    end
  end
end

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