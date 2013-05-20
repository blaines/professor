module Professor
  module Interface
    class Ruby
      def self.check(file)
        `ruby`
      end
    end
  end
end