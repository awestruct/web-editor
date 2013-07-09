#require 'bundler'
require 'awestruct/version'
require 'awestruct/cli/generate'
require 'logger'
require 'json'
require 'optparse'
#require 'rubygems'

options = {}

begin
OptionParser.new do |opts|
  opts.banner = "Usage: exec_awestruct.rb [options]"

  opts.on('--repo REPOSITORY', 'Repository to use') do |repo|
    options[:repo] = repo
  end

  opts.on('--profile PROFILE', 'Profile to build') do |profile|
    options[:profile] = profile
  end

  opts.on('--url BASE_URL', 'BaseURL to use during generation') do |url|
    options[:url] = url
  end

  opts.on_tail('-h', '--help', 'show this message') do
    $stdout.puts opts
    exit(0)
  end
end.parse!
rescue OptionParser::MissingArgument => e
  puts e.to_str.capitalize.gsub('argument:', 'value for:')
  puts 'That option requires a value. Please try again.'
  exit
end

required_opts = [:repo, :profile, :url]
required_missing = false

required_opts.each do |opt|
  if options.has_key?(opt)
    next
  else
    puts "Required option --#{opt} missing."
    required_missing = true
  end
end

if required_missing
  exit
end

Dir.chdir "/home/jporter/projects/ruby/awestruct-web-editor/repos/#{options[:repo]}" do
  #ENV.keys.each do |key|
  #  $stderr.puts "DEBUG:: ENV[#{key}] = #{ENV[key]}"
  #end
  #Bundler.require
  $LOG = Logger.new(StringIO.new)
  $LOG.level = Logger::ERROR
  engine = Awestruct::Engine.new(Awestruct::Config.new)
  engine.adjust_load_path
  engine.load_default_site_yaml
  engine.load_site_yaml options[:profile]
  engine.set_base_url "#{options[:url]}/preview/repos/#{options[:repo]}", "#{options[:url]}/preview/repos/#{options[:repo]}"
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

  $stdout.puts JSON.dump source_to_output
end

