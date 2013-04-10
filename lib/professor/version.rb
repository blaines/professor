module Professor
  # http://semver.org/
  # http://rubygems.rubyforge.org/rubygems-update/Gem/Version.html
  MAJOR = 0
  MINOR = 1
  PATCH = 0
  VERSION = ENV['RELEASE'] == "true" ? "#{MAJOR}.#{MINOR}.#{PATCH}" : "#{MAJOR}.#{MINOR}.#{PATCH+1}.pre#{ENV['BUILD_NUMBER']}"
end