# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tdigest/version'

Gem::Specification.new do |spec|
  spec.name          = "tdigest"
  spec.version       = TDigest::VERSION
  spec.authors       = ["Sebastian Wallin"]
  spec.email         = ["sebastian.wallin@gmail.com"]

  spec.summary       = %q{Ruby implementation of Dunning's T-Digest for streaming quantile approximation}
  spec.description   = %q{Ruby implementation of Dunning's T-Digest for streaming quantile approximation}
  spec.homepage      = "https://github.com/castle/tdigest"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'rbtree', '~> 0.4.2'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.8.3'
  spec.add_development_dependency 'coveralls', '~> 0.8.10'
  spec.add_development_dependency 'simplecov', '~> 0.11.1'
end
