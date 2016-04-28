# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'owrb/version'

Gem::Specification.new do |spec|
  spec.name          = "owrb"
  spec.version       = Owrb::VERSION
  spec.authors       = ["liveralmask"]
  spec.email         = ["liveralmask.lisk@gmail.com"]

  spec.summary       = %q{Web scripts.}
  spec.description   = %q{Web scripts.}
  spec.homepage      = "https://github.com/liveralmask/owrb"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  
  spec.add_dependency "nokogiri"
  spec.add_dependency "watir"
end
