require "sinatra/base"
require "sinatra/json"
require 'json'
require 'slim'
require 'sprockets'
require 'sinatra/sprockets-helpers'
require_relative 'helpers/repository'
require_relative 'helpers/link'

module AwestructWebEditor
  class App < Sinatra::Base
    register Sinatra::Sprockets::Helpers
    set :sprockets, Sprockets::Environment.new(root)
    set :assets_prefix, '/assets'
    set :public_folder, '/public'
    set :digest_assets, true

    configure do
      # Setup Sprockets
      sprockets.append_path File.join(root, 'assets', 'stylesheets')
      sprockets.append_path File.join(root, 'assets', 'javascripts')
      sprockets.append_path File.join(root, 'assets', 'images')
      sprockets.append_path File.join(root, 'assets', 'font')

      configure_sprockets_helpers
    end

    configure :development do
      require "sinatra/reloader"
      register Sinatra::Reloader
      also_reload 'app.rb'
      also_reload 'models/**/*.rb'
      set :raise_errors, true
      enable :logging, :dump_errors, :raise_errors
    end


    helpers Sinatra::JSON

    get '/' do
      slim :index
    end

    get '/assets/*' do
      sprockets
    end

    get '/partials/*.*' do |basename, ext|
      logger.info "Rendering partial #{basename}"
      slim "partials/#{basename}".to_sym
    end

    get '/repo/:reponame' do |reponame|
      files = AwestructWebEditor::Repository.new({"name" => reponame}).all_files
      return_links = files.map { |f| AwestructWebEditor::Link.new({'url' => url("/repo/#{reponame}/#{f}"), 'text' => f}) }
      [200, JSON.dump(:links => return_links)]
    end

    get '/repo' do

    end
  end
end