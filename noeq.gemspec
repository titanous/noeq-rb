# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Jonathan Rudenberg"]
  gem.email         = ["jonathan@titanous.com"]
  gem.description   = %q{Ruby noeqd GUID client}
  gem.summary       = %q{Ruby noeqd GUID client}
  gem.homepage      = "http://github.com/titanous/noeq-rb"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "noeq"
  gem.require_paths = ["lib"]
  gem.version       = "0.1.0"
end
