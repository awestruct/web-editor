require 'sinatra/asset_pipeline/task.rb'
require 'rspec/core/rake_task'
require 'guard'

require './app'

task :default => 'test:spec'

namespace :test do
  if !defined?(RSpec)
    puts "spec targets require RSpec"
  else
    desc "Run all specifications"
    RSpec::Core::RakeTask.new(:spec) do |t|
      t.pattern = 'spec/**/*_spec.rb'
    end
  end

  desc "Start Guard to listen for changes and run specs"
  task :guard do
    Guard.start(:guardfile => 'Guardfile')
    Guard.run_all
    while ::Guard.running do
      sleep 0.5
    end
  end
end

Sinatra::AssetPipeline::Task.define! AwestructWebEditor
