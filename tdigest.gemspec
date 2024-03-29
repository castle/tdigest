# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tdigest/version'

java = (ENV['RUBY_PLATFORM'] == 'java')

Gem::Specification.new do |spec|
  spec.name          = 'tdigest'
  spec.version       = TDigest::VERSION
  spec.authors       = ['Sebastian Wallin']
  spec.email         = ['sebastian.wallin@gmail.com']

  spec.summary       = 'TDigest for Ruby'
  spec.description   = "Ruby implementation of Dunning's T-Digest for streaming quantile approximation"
  spec.homepage      = 'https://github.com/castle/tdigest'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.platform      = java ? 'java' : 'ruby'

  if java
    spec.add_runtime_dependency 'rbtree-jruby', '~> 0.2.1'
  else
    spec.add_runtime_dependency 'rbtree3', '~> 0.7.1'
  end

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'coveralls', '~> 0.8.10'
  spec.add_development_dependency 'minitest', '~> 5.8'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'simplecov', '~> 0.16.0'
end
