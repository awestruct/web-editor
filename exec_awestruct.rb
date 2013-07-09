require 'bundler'
require 'awestruct/version'
require 'awestruct/cli/generate'
require 'logger'
require 'json'

Dir.chdir '/home/jporter/projects/ruby/awestruct-web-editor/repos/asciidoctor.github.com' do
  Bundler.require
  $LOG = Logger.new(StringIO.new)
  $LOG.level = Logger::ERROR
  engine = Awestruct::Engine.new(Awestruct::Config.new)
  engine.adjust_load_path
  engine.load_default_site_yaml
  #engine.load_site_yaml profile
  engine.load_site_yaml 'developement'
  #engine.set_base_url url, url
  engine.set_base_url 'http://localhost:9292/preview/repos/asciidoctor.github.com', 'http://localhost:9292/preview/repos/asciidoctor.github.com'
  engine.load_yamls
  engine.load_pipeline
  engine.load_pages
  engine.execute_pipeline
  engine.configure_compass
  engine.set_urls engine.site.pages
  engine.build_page_index
  engine.generate_output

  source_to_output = {}
  engine.site.pages.each do |p| 
    source_to_output[p.relative_source_path] = p.output_path unless source_to_output.include? p.relative_source_path 
  end

  puts JSON.dump source_to_output
end

