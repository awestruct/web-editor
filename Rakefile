task :default => 'test:spec'

namespace :assets do 
  desc 'compile assets'
  task :compile => [:compile_js, :compile_css] {}

  desc 'Clean compiled assets'
  task :clean do
    # TODO implement
  end

  desc "Compile css assets"
  task :compile_css do

    require 'compass'
    %w(configuration frameworks app_integration actions compiler commands).each do |lib|
      require "compass/#{lib}"
    end
    require 'zurb-foundation'

    Compass::Commands::UpdateProject.new(File.dirname(__FILE__), {
                                                                    :framework => 'zurb-foundation',
                                                                    :project_type => :stand_alone,
                                                                    :css_dir => 'public/stylesheets',
                                                                    :http_path => '/',
                                                                    :sass_dir => 'assets/sass',
                                                                    :images_dir => 'assets/images',
                                                                    :fonts_dir => 'assets/fonts',
                                                                    :javascripts_dir => 'assets/javascripts',
                                                                    :output_style => :compressed 
                                                                  }).perform
  end

  desc 'Compile JavaScript Assets'
  task :compile_js do
    require 'sprockets'
    require 'uglifier'

    sprockets = Sprockets::Environment.new 
    sprockets.append_path File.join('assets', 'javascripts')
    #sprockets.js_compressor = :uglifier

    asset     = sprockets['package.js']
    outpath   = File.join('public', 'javascripts')
    outfile   = Pathname.new(outpath).join('package.js') # may want to use the digest in the future?
 
    FileUtils.mkdir_p outfile.dirname
 
    asset.write_to(outfile)
    puts "successfully compiled js assets"
  end
end

namespace :test do
  require 'rspec/core/rake_task'

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
    require 'guard'
    Guard.start(:guardfile => 'Guardfile')
    Guard.run_all
    while ::Guard.running do
      sleep 0.5
    end
  end
end

