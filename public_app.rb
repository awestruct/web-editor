require 'sinatra/base'
require 'sass'
require 'json'
require 'rack/ssl'
require 'slim'
require 'sprockets'
require 'compass'
require 'sprockets-sass'
require 'sprockets-helpers'
require 'bundler'
require 'open3'
require 'date'
require 'digest/sha2'
require 'securerandom'
require 'octokit'
require 'uri'
require 'sinatra/cookies'

require_relative 'helpers/repository'

module AwestructWebEditor
  class PublicApp < Sinatra::Base
    set :sprockets, Sprockets::Environment.new(root)
    set :ssl, lambda { |_| development? }
    enable :sessions

    use Rack::SSL, :exclude => lambda { |_| development? }

    configure do
      # Setup Sprockets
      Sprockets::Helpers.configure do |config|
        config.environment = sprockets

        %w(sass javascripts images fonts).each do |dir|
          sprockets.append_path File.join(root, 'assets', dir)
        end
      end
    end

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
      also_reload 'models/**/*.rb'
      set :raise_errors, true
      enable :logging, :dump_errors, :raise_errors
    end

    configure :production do
      #sprockets.js_compressor = :uglifier
      sprockets.css_compressor = :scss
    end

    # Security
    before %r{^\/(repo|preview|settings)(\/[\w]+)*} do
      check_token env['token']
    end

    get '/token' do
      get_token
    end

    # From the secure portion
    get '/settings' do
      settings = read_settings

      if settings.is_a? Hash
        settings = settings.reject { |k,v| /oauth|client/ =~ k}
      end

      [200, JSON.dump(settings)]
    end

    post '/settings' do
      settings = { 'repo' => params['repo'], 'username' => params['username'], 'password' => params['password'] }
      write_settings settings
    end

    put '/settings' do
      settings = { 'repo' => params['repo'], 'username' => params['username'], 'password' => params['password'] }
      get_github_token settings
      clone_result = AwestructWebEditor::Repository.new(:name => URI(settings['repo']).path.split('/').last,
                                                        :token => session[:github_auth]).clone
      if clone_result.first != 0
        [500, clone_result[1]]
      else
        [200, 'Successfully cloned']
      end
    end

    error do
      "An error occurred while processing: #{env['sinatra.error'].name}. Message: #{env['sinatra.error'].message}"
    end

    # Views

    get '/' do
      slim :index
    end

    get '/partials/*.*' do |basename, ext|
      slim "partials/#{basename}".to_sym
    end

    # Application API

    # Git related APIs
    post '/repo/:repo_name/change_set' do |repo_name|
      create_repo(repo_name).create_branch params[:name]
    end

    post '/repo/:repo_name/commit' do |repo_name|
      unless create_repo(repo_name).commit(params[:message]).nil?
        [200, 'Success']
      else
        [500, 'Error committing']
      end
    end

    post '/repo/:repo_name/pull_latest' do |repo_name|
      repo = create_repo(repo_name)
      repo.rebase(params.include? :overwrite)
    end

    # Repo APIs
    post '/repo/:repo_name/push' do |repo_name|
      repo = create_repo(repo_name)
      repo.push
      repo.pull_request params[:title], params[:message]
    end

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

    # File related APIs

    get '/repo/:repo_name' do |repo_name|
      additional_allows = params[:allow] || ''
      files = create_repo(repo_name).all_files([Regexp.compile(additional_allows)])
      return_links = {}
      files.each do |f|
        links = []

        unless f[:directory]
          links = links_for_file(f, repo_name)
        end

        if f[:path_to_root] =~ /\./
          return_links[f[:location]] = { :links => links, :directory => f[:directory], :children => {},
                                         :path => File.join(f[:path_to_root], f[:location]) }
        else
          directory_paths = f[:path_to_root].split(File::SEPARATOR)
          final_location = return_links[directory_paths[0]]
          directory_paths.delete(directory_paths[0])
          directory_paths.each { |path| final_location = final_location[:children][path] } unless directory_paths.nil?
          final_location[:children][f[:location]] = { :links => links, :directory => f[:directory], :children => {},
                                                      :path => File.join(f[:path_to_root], f[:location]) }
        end
      end
      [200, JSON.dump(return_links)]
    end

    get '/repo/:repo_name/*' do |repo_name, path|
      repo = create_repo(repo_name)
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
      result = create_repo(repo_name).remove_file path
      result ? [200] : [500]
    end

    # Preview APIs

    get '/preview/:repo_name' do |repo_name|
      retrieve_rendered_file(create_repo repo_name, 'index', 'html')
    end

    get '/preview/:repo_name/*.*' do |repo_name, path, ext|
      retrieve_rendered_file(create_repo repo_name, path, ext)
    end

    helpers do
      include Sprockets::Helpers
      include Sinatra::Cookies

      def check_token(token)
        unless env['token'] == (Digest::SHA512.new << "#{session[:csrf]}#{env['time']}").to_s
          error 401, 'You are not allowed to do this.'
        end
      end

      def get_token
        time = DateTime.now.iso8601
        if session[:csrf].nil?
          session[:csrf] = (Digest::SHA512.new << SecureRandom.uuid << SecureRandom.random_bytes).to_s
        end
        response.headers['base_token'] = session[:csrf]
        (Digest::SHA512.new << "#{session[:csrf]}#{time}").to_s
      end

      def settings_storage_file
        if ENV['OPENSHIFT_DATA_DIR']
          @base_repo_dir = File.join(ENV['OPENSHIFT_DATA_DIR'], 'repos')
          FileUtils.mkdir(File.join @base_repo_dir) unless File.exists? @base_repo_dir
        elsif ENV['RACK_ENV'] =~ /test/
          @base_repo_dir = 'tmp/repos'
        else
          @base_repo_dir = 'repos'
        end
        File.join(@base_repo_dir, 'github-settings')
      end

      def read_settings
        if File.exists?(settings_storage_file)
          File.open(settings_storage_file, 'r') do |f|
            get_github_token JSON.load(f)
          end
        else
          ''
        end
      end

      def write_settings(settings)
        File.open(settings_storage_file, 'w+') do |f|
          f.write JSON.dump(settings)
        end
      end

      def get_github_token(settings)
        unless session[:github_auth]
          client = Octokit::Client.new(:login => settings['username'], :password => settings['password'])
          # if token_id (get token, save in session)
          result = {}
          if settings['token_id']
            result = client.authorization settings['token_id']
          else
            result = client.create_authorization :note => 'Awestruct Web Editor', :scopes => ['repo'],
                                                 :note_url => request.url[0..(request.url.index('settings') - 1)]
            settings['token_id'] = result['id']
          end

          if result.empty?
            error 500, 'Error authenticating with GitHub'
          end

          session[:github_auth] = result['token']
          settings.delete('password')
          write_settings settings
        end
        settings
      end

      def create_repo(repo_name)
        AwestructWebEditor::Repository.new({ :name => repo_name, :token => session[:github_auth] })
      end

      def links_for_file(f, repo_name)
        links = []
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'GET' })
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'PUT' })
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'POST' })
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}"), :text => f[:location], :method => 'DELETE' })
        links << AwestructWebEditor::Link.new({ :url => url("/repo/#{repo_name}/#{f[:path_to_root]}/#{f[:location]}/preview"), :text => "Preview #{f[:location]}", :method => 'GET' })
      end

      def save_or_create(repo_name, path)
        request.body.rewind # in case someone already read it
        repo = create_repo repo_name
        repo.save_file path, params[:content]

        retrieve_rendered_file(repo, path) unless ENV['RACK_ENV'] =~ /test/
      end

      def retrieve_rendered_file(repo, path)
        Bundler.with_clean_env do
          Open3.popen3("ruby exec_awestruct.rb --repo #{repo.name} --url '#{request.scheme}://#{request.host}' --profile development") do |stdin, stdout, stderr, thr|
            mapping = nil
            stdout.each_line do |line|
              if line.match(/^\{.*/)
                mapping = JSON.load line
              end
            end

            if !mapping.nil? && mapping.include?('/' + path)
              [200, File.open(File.join(repo.base_repository_path, '_site', mapping['/' + path]), 'r') { |f| f.readlines }]
            else
              [500, JSON.dump("Error: #{path} not rendered")]
            end
          end
        end
      end
    end
  end
end
