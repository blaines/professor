module Professor
  # http://semver.org/
  # http://rubygems.rubyforge.org/rubygems-update/Gem/Version.html
  MAJOR = ENV['MAJOR'] || 0
  MINOR = ENV['MINOR'] || 0
  PATCH = ENV['PATCH'] || 0
  VERSION = ENV['RELEASE'] ? "#{MAJOR}.#{MINOR}.#{PATCH}" : "#{MAJOR}.#{MINOR}.#{PATCH}.pre#{ENV['BUILD_NUMBER']}"
end