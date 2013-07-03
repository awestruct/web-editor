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
      require 'sinatra/reloader'
      register Sinatra::Reloader
      also_reload 'app.rb'
      also_reload 'models/**/*.rb'
      set :raise_errors, true
      enable :logging, :dump_errors, :raise_errors
    end

    # Views

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

    # Application API

    # Repo APIs

    get '/repo' do
      repo_base = ENV['RACK_ENV'] =~ /test/ ? 'tmp/repos' : 'repos'
      return_structure = {}
      Dir[repo_base + '/*'].each do |f|
        if File.directory? f
          basename = File.basename f
          return_structure[basename] = { 'links' => [AwestructWebEditor::Link.new({ :url => url("/repo/#{basename}"),
                                                                                    :text => f,
                                                                                    :method => 'GET' })] }
        end
      end
      [200, JSON.dump(return_structure)]
    end

    # TODO put /repo/setup # params up for discussion

    # File related APIs

    get '/repo/:repo_name' do |repo_name|
      files = AwestructWebEditor::Repository.new({ 'name' => repo_name }).all_files
      return_links = {}
      files.each do |f|
        links = []

        unless f[:directory]
          links = links_for_file(f, repo_name)
        end

        if f[:path_to_root] =~ /\./
          return_links[f[:location]] = { :links => links, :directory => f[:directory], :children => {} }
        else
          directory_paths = f[:path_to_root].split(File::SEPARATOR)
          final_location = return_links[directory_paths[0]]
          directory_paths.delete(directory_paths[0])
          directory_paths.each { |path| final_location = final_location[:children][path] } unless directory_paths.nil?
          final_location[:children][f[:location]] = { :links => links, :directory => f[:directory], :children => {} }
        end
      end
      [200, JSON.dump(return_links)]
    end

    get '/repo/:repo_name/*' do |repo_name, path|
      repo = AwestructWebEditor::Repository.new({ :name => repo_name })
      json_return = { :content => repo.file_content(path), :links => links_for_file(repo.file_info(path), repo_name) }
      [200, JSON.dump(json_return)]
    end

    post '/repo/:repo_name/*' do |repo_name, path|
      save_or_create(repo_name, path)
    end

    put '/repo/:repo_name/*' do |repo_name, path|
      save_or_create(repo_name, path)
    end

    delete '/repo/:repo_name/*' do |repo_name, path|
      repo = AwestructWebEditor::Repository.new({ :name => repo_name })
      result = repo.remove_file path
      result ? [200] : [500]
    end

    # Preview APIs
    # TODO get '/repo/:repo_name/preview' # comment about rethinking this one
    # TODO get '/repo/:repo_name/*/preview'

    # Git related APIs
    # TODO post /repo/:reponame/commit # params[:message]
    # TODO post /repo/:reponame/push

    helpers do
      Sinatra::JSON

      def links_for_file(f, repo_name)
        links = []
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'GET' })
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'PUT' })
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'POST' })
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'DELETE' })
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}/preview"), :text => "Preview #{f[:location]}", :method => 'GET' })
      end

      def save_or_create(repo_name, path)
        repo = AwestructWebEditor::Repository.new({ :name => repo_name })
        request.body.rewind # in case someone already read it
        repo.save_file path, params[:content]
        [200, JSON.dump({ :links => links_for_file(repo.file_info(path), repo_name) })]
      end
    end
  end
end
