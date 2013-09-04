require 'rspec/core/rake_task'
require 'guard'
require 'sprockets'
require 'sprockets-sass'
require 'sass'
require 'compass'
require 'zurb-foundation'

task :default => 'test:spec'

namespace :assets do
  desc 'compile assets'
  task :compile => [:compile_js, :compile_css] do
  end

  desc 'compile javascript assets'
  task :compile_js do
    sprockets = Sprockets::Environment.new 
    sprockets.append_path File.join('assets', 'javascripts')

    asset     = sprockets['app.js']
    outpath   = File.join('public', 'javascripts')
    outfile   = Pathname.new(outpath).join('app.min.js') # may want to use the digest in the future?
 
    FileUtils.mkdir_p outfile.dirname
 
    asset.write_to(outfile)
    asset.write_to("#{outfile}.gz")
    puts "successfully compiled js assets"
  end
 
  desc 'compile css assets'
  task :compile_css do
    sprockets = Sprockets::Environment.new 
    Sprockets::Sass.options[:output_style] = :compressed 
    %w(sass images fonts).each do |dir|
      sprockets.append_path File.join('assets', dir)
    end

    asset     = sprockets['app.css.scss']
    outpath   = File.join('public', 'stylesheets')
    outfile   = Pathname.new(outpath).join('application.min.css') # may want to use the digest in the future?
 
    FileUtils.mkdir_p outfile.dirname
 
    asset.write_to(outfile)
    asset.write_to("#{outfile}.gz")
    puts "successfully compiled css assets"
  end
end

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

