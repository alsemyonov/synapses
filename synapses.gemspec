# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'synapses/version'

Gem::Specification.new do |spec|
  spec.name          = 'synapses'
  spec.version       = Synapses::VERSION
  spec.authors       = ['Alexander Semyonov']
  spec.email         = %w(al@semyonov.us)
  spec.description   = %q{MQ-based application communication and event processing}
  spec.summary       = %q{Synapses connecting your applications}
  spec.homepage      = 'https://github.com/alsemyonov/synapses'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_runtime_dependency 'eventmachine'
  spec.add_runtime_dependency 'amqp'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
