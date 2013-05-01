module Professor
  module Git
    # This class represents a range of git changesets
    class CommitCheckRange
      # Initialize the object with a Git object and start/end changes.
      # Use the SHA or tag for the start/end
      def initialize(git, startsha, endsha)
        @git = git
        @start_cset = startsha
        @end_cset = endsha
        @commit_sets = []
      end

      # Populate the set of changesets
      def check_sets
        sets = @git.log.between(@start_cset, @end_cset)
        sets.each do |cset|
          commit_check_set = CommitCheckSet.new(@git, cset)
          @commit_sets.push(commit_check_set)
        end
      end

      # Check if the range of changesets has any changeset that violates the policy
      # of always checking in a schema.rb together with a new db/migrate/.
      def has_migrations_without_schema_update?
        if @commit_sets.empty?
          self.check_sets
        end

        violations = 0

        # Look at each changeset in range and see if it violates the policy
        @commit_sets.each do |commit_set|
          if commit_set.has_migration_file? && !commit_set.has_modified_schema?
            puts 'Migrations found without schema update for ' + commit_set.to_s
            violations += 1
          elsif commit_set.has_migration_file? && commit_set.has_modified_schema?
            puts 'Migrations found with schema update for ' + commit_set.to_s
          else
            puts 'No migrations found in changeset ' + commit_set.to_s
          end
        end
        return violations > 0
      end

    end
  end
end