module Professor
  module Git
    # This class wraps a Git::Object to add additional functionality such
    # as checking for existance of specific files in the change
    class CommitCheckSet
      # git command to show only files that are modified/added
      LIST_FILE_COMMAND = 'git show --pretty="format:" --name-only '

      def initialize(git, changeset)
        @git = git
        @changeset = changeset
      end

      # Check if changeset has a DB migration file
      # @return [Boolean]
      def has_migration_file?
        return has_files?("^db/migrate/.*\.rb$")
      end

      # Check if changeset has a schema.rb update
      # @return [Boolean]
      def has_modified_schema?
        return has_files?("^db/schema.rb$")
      end

      # Return a one-line representation of the changeset
      # @return [String]
      def to_s
        # Get only the first line of the commit message; indicate multi-line
        # messages by adding a "[...]"
        message_lines =  @changeset.message.split($/)
        first_message_line = message_lines[0]
        first_message_line += " [...]" if message_lines.size > 1
        return "\"" + first_message_line + "\" (" + @changeset.committer.name + ") - " + @changeset.sha
      end

      private
      # Check if changeset contains at least one file that matches the pattern
      # @param [String] pattern
      # @return [Boolean]
      def has_files?(pattern)
        ls_output = LIST_FILE_COMMAND + @changeset.sha
        files = `#{ls_output}`.split($/)
        found_files = files.grep(%r{#{pattern}})
        return found_files.size > 0
      end


    end
  end
end