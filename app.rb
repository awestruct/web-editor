require "sinatra/base"
require "sinatra/json"
require 'multi_json'
require 'slim' 
require 'sprockets'
require 'sinatra/sprockets-helpers'

class AwestructWebEditor < Sinatra::Base 
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

  get '/repo/:reponame' do

  end
end
