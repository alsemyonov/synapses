require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task :spec do
    abort 'RSpec is not available. In order to run specs, you must: gem install rspec'
  end
end

namespace :doc do
  begin
    require 'yard'
    YARD::Rake::YardocTask.new(:default)
  rescue LoadError
    task :default do
      abort 'YARD is not available. In order to run yardoc, you must: gem install yard'
    end
  end

  begin
    require 'yardstick/rake/measurement'

    Yardstick::Rake::Measurement.new(:measure) do |measurement|
      measurement.output = 'doc/measurement.txt'
    end
    task doc: :measure
  rescue LoadError
    task :measure do
      abort 'YARDStick is not available. In order to measure documentation coverage, you should run `gem install yardstick`'
    end
  end

  begin
    require 'yardstick/rake/verify'
    Yardstick::Rake::Verify.new(:verify) do |verify|
      verify.threshold = 100
    end
    task doc: :verify
  rescue LoadError
    task :verify do
      abort 'YARDStick is not available. In order to verify documentation coverage, you should run `gem install backports yardstick`'
    end
  end
end

task doc: 'doc:default'


task default: :spec
