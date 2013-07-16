require 'rspec'
require 'rspec/expectations'
require 'rack'
require 'rack/test'
require 'sinatra'
require 'octokit'
require 'git'
require 'fileutils'
require 'shellwords'
require 'uri'

require_relative '../app.rb'
require_relative '../helpers/repository'
require_relative '../helpers/link'

APP = Rack::Builder.parse_file(File.join(File.dirname(__FILE__), '..', 'config.ru')).first

RSpec.configure do |config|
  ENV['RACK_ENV'] = 'test'
  config.include Rack::Test::Methods

  def app
    APP
  end

  config.before(:suite) do
    unless File.exists? (File.join(File.dirname(__FILE__), '..', 'tmp/repos/awestruct.org'))
      FileUtils.mkdir_p(File.join(File.dirname(__FILE__), '..', 'tmp/repos'))
      Git.clone('git@github.com:awestruct/awestruct.org.git', 'awestruct.org',
                :path => File.join(File.dirname(__FILE__), '..', 'tmp/repos'))
    end
    #unless File.exists? (File.join(File.dirname(__FILE__), '..', 'tmp/repos/github-settings'))
    #  File.open(File.join(File.dirname(__FILE__), '..', 'tmp/repos/github-settings'), 'w+') do |f|
    #  end
    #end
  end

  config.after(:suite) do
    FileUtils.rm File.join(File.dirname(__FILE__), '..', 'tmp/repos/github-settings') if File.exists?(File.join(File.dirname(__FILE__), '..', 'tmp/repos/github-settings'))

    git = Git.open File.join(File.dirname(__FILE__), '..', 'tmp/repos/awestruct.org')
    git.reset_hard 'origin/master'
  end
end
