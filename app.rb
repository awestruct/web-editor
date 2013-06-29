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
      return_links = {}
      files.each do |f|
        links = []

        unless f[:directory]
          links << AwestructWebEditor::Link.new({:url => url("/repo/#{reponame}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'GET'})
          links << AwestructWebEditor::Link.new({:url => url("/repo/#{reponame}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'PUT'})
          links << AwestructWebEditor::Link.new({:url => url("/repo/#{reponame}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'POST'})
          links << AwestructWebEditor::Link.new({:url => url("/repo/#{reponame}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'DELETE'})
        end

        if f[:path_to_root] =~ /\./
          return_links[f[:location]] = {:links => links, :directory => f[:directory], :children => {}}
        else
          directory_paths = f[:path_to_root].split(File::SEPARATOR)
          final_location = return_links[directory_paths[0]]
          directory_paths.delete(directory_paths[0])
          directory_paths.each {|path| final_location = final_location[:children][path]} unless directory_paths.nil?
          final_location[:children][f[:location]] = {:links => links, :directory => f[:directory], :children => {}}
        end
      end
      [200, JSON.dump(return_links)]
    end

    get '/repo' do

    end
  end
end

