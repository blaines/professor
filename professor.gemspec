# -*- encoding: utf-8 -*-
require File.expand_path('../lib/professor/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Blaine Schanfeldt"]
  gem.email         = ["blaine@lookout.com"]
  gem.description   =
    %q{Professor teaches you to be a better developer}
  gem.summary       = %q{
    Teaches you to be a better developer, the professor will help you learn git, and also grade your code.
  }
  gem.homepage      = "http://blaines.me"

  gem.executables   = []
  gem.files         = Dir.glob("{spec,lib}/**/*.rb") + %w(
                        README.md
                        professor.gemspec
                      )
  gem.test_files    = Dir.glob("spec/**/*.rb")
  gem.name          = "professor"
  gem.require_paths = ["lib"]
  gem.bindir        = "bin"
  gem.executables  << "professor"
  gem.version       = Professor::VERSION
  gem.has_rdoc      = false
  gem.add_dependency 'cane'
  gem.add_dependency 'thor'
  gem.add_dependency 'colorize'
  gem.add_development_dependency 'rspec', '~> 2.0'
  gem.add_development_dependency 'rake'
end