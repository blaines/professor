module Professor
  # http://semver.org/
  # http://rubygems.rubyforge.org/rubygems-update/Gem/Version.html
  MAJOR = 0
  MINOR = 1
  PATCH = 3
  VERSION = ENV['RELEASE'] == "true" ? "#{MAJOR}.#{MINOR}.#{PATCH}" : "#{MAJOR}.#{MINOR}.#{PATCH}.pre#{ENV['BUILD_NUMBER']}"
end