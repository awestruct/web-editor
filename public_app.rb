# Core
require 'open3'
require 'date'
require 'digest/sha2'
require 'securerandom'

# External
require 'bundler'
require 'rack/ssl'
require 'rack/auth/basic'
require 'sinatra/base'
require 'sinatra/cookies'
require 'octokit'
require 'json'

# Front end
require 'sass'
require 'slim'
require 'sprockets'
require 'compass'
require 'sprockets-sass'
require 'sprockets-helpers'

require_relative 'helpers/repository'
require_relative 'helpers/link'

module AwestructWebEditor
  class PublicApp < Sinatra::Base
    set :sprockets, Sprockets::Environment.new(root)
    set :ssl, lambda { |_| development? }

    use Rack::Session::Cookie, :key => 'awestruct-editor-session',
                               :path => '/',
                               :secret => (ENV['OPENSHIFT_APP_UUID'] || 'localhost'), # TODO: add something for Contegix
                               :old_secret => '6b0385be07bcc169a1ee49ddb4b33c9d31cc668504dd2b5b59185253dcf55b42d7f6c766f546f638cd3fe829b9d32a59db61a5938d75ab2f2c15336a2368c9e6'

    #use Rack::SSL, :exclude => lambda { |_| development? }

    configure do
      # Setup logging
      enable :logging
      log_file = File.new(File.join((ENV['OPENSHIFT_RUBY_LOG_DIR'] || 'log'), 'application.log' ), 'a+')
      log_file.sync = true
      set :logger, Logger.new(log_file, 'daily')
      use Rack::CommonLogger, log_file

      # Setup Sprockets
      Sprockets::Helpers.configure do |config|
        config.environment = sprockets

        %w(sass javascripts images fonts).each do |dir|
          sprockets.append_path File.join(root, 'assets', dir)
        end
        #if production?
          %w(font stylesheets javascripts images).each do |dir|
            sprockets.prepend_path File.join('public', dir)
          end
          sprockets.index
        #end
      end
    end

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
      also_reload 'models/**/*.rb'
      set :raise_errors, true
      enable :dump_errors, :raise_errors
    end

    # Security
    before %r{^/(repo|settings)(/[\w]+)*} do
      pass if ((request.path_info =~ %r{^/repo}) && (request.path_info =~ /images/))
      check_token
    end

    before '/token' do
      unless session['gh-pass'] and read_settings()['username']
        auth ||= Rack::Auth::Basic::Request.new request.env
        if auth.provided? && auth.basic? && auth.credentials
          session['username'] = auth.credentials[0]
          session['gh-pass'] = auth.credentials[1]
          begin
            get_octokit_client(auth.credentials[0]).user
            write_settings(read_settings().merge({'username' => session['username']}))
          rescue Octokit::Unauthorized => e
            halt 401, e.to_s
          end
        else
          halt 401, 'Unauthorized'
        end
      end
    end

    get '/token' do
      get_token
    end

    # From the secure portion
    get '/settings' do
      settings = read_settings

      if settings.is_a? Hash
        settings = settings.reject { |k,_| /oauth|client/ =~ k}
      end

      [200, JSON.dump(settings)]
    end

    post '/settings' do
      settings = read_settings().merge({ 'repo' => params['repo'].sub(%r{^(((git@github.com:)|(https(s)?://github.com/)?))},'').sub(/\.git$/,'') })
      write_settings settings
    end

    put '/settings' do
      settings = read_settings().merge({ 'repo' => params['repo'].sub(%r{^(((git@github.com:)|(https(s)?://github.com/)?))},'').sub(/\.git$/,'') })
      logger.debug "Settings: #{settings}"
      get_github_token settings
      repo =  AwestructWebEditor::Repository.new(:name => settings['repo'].split('/').last,
                                                 :token => session[:github_auth], :username => session['username'])
      repo.init_empty
      repo.add_creds

      clone_result = repo.clone_repo
      if clone_result.first != 0
        [500, clone_result[1]]
      else
        [200, 'Successfully cloned']
      end
    end

    error do
      "An error occurred while processing: #{env['sinatra.error']}. Message: #{env['sinatra.error'].message}"
    end

    # Views

    get '/' do
      slim :index
    end

    get '/partials/*.*' do |basename, _|
      slim "partials/#{basename}".to_sym
    end

    # Application API

    # Git related APIs
    post '/repo/:repo_name/change_set' do |repo_name|
      create_repo(repo_name).create_branch params[:name]
    end

    post '/repo/:repo_name/commit' do |repo_name|
      if create_repo(repo_name).commit(params[:message]).nil?
        [500, 'Error committing']
      else
        [200, 'Success']
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
      repo_base = ENV['RACK_ENV'] =~ /test/ ? "tmp/repos/#{session('username')}" : "repos/#{session('username')}"
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

    get '/repo/:repo_name/images' do |repo_name|
      repo = create_repo(repo_name)
      files = repo.all_files([], 'images')

      json_return = {}
      files.each do |f|
        unless f[:directory]
          json_return[f[:location]] = { :content => repo.file_content(File.join('images', f[:location]))}
        end
      end

      [200, JSON.dump(json_return)]
    end

	get '/repo/:repo_name/branches' do |repo_name|
      repo = create_repo(repo_name)
      [200, JSON.dump(repo.branches)]
    end

    post '/repo/:repo_name/branches/:branch_name' do |repo_name, branch_name|
      repo = create_repo(repo_name).switch_branch branch_name
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
      retrieve_rendered_file(create_repo(repo_name), 'index.html.slim')
    end

    get '/preview/:repo_name/*' do |repo_name, path|
      retrieve_rendered_file(create_repo(repo_name), path)
    end

    helpers do
      include Sprockets::Helpers
      include Sinatra::Cookies

      def check_token
        unless env['HTTP_TOKEN'] == (Digest::SHA512.new << "#{session[:csrf]}#{env['HTTP_TIME']}").to_s
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
          base_repo_dir = File.join(ENV['OPENSHIFT_DATA_DIR'], 'repos', session['username'])
        elsif ENV['RACK_ENV'] =~ /test/
          base_repo_dir = "tmp/repos/#{session['username']}"
        else
          base_repo_dir = "repos/#{session['username']}"
        end

        FileUtils.mkdir_p(File.join base_repo_dir) unless File.exists? base_repo_dir
        File.join(base_repo_dir, 'github-settings')
      end

      def read_settings
        if File.exists?(settings_storage_file)
          File.open(settings_storage_file, 'r') do |f|
            get_github_token JSON.load(f)
          end
        else
          {}
        end
      end

      def write_settings(settings)
        File.open(settings_storage_file, 'w+') do |f|
          f.write JSON.dump(settings)
        end
      end

      def get_github_token(settings)
        unless session[:github_auth] && settings['token_id']
          client = get_octokit_client(session['username'])
          logger.debug "github_client: #{client}"
          # if token_id (get token, save in session)
          result = {}
          if settings['token_id']
            result = client.authorization settings['token_id']
            logger.debug "result from authorization: #{result}"
          else
            result = client.create_authorization :note => 'Awestruct Web Editor', :scopes => ['repo']
            logger.debug "result from create_authorization: #{result}"
            settings['token_id'] = result['id']
          end

          if result.empty?
            error 500, 'Error authenticating with GitHub'
          end

          session[:github_auth] = result['token']
          settings.delete('password')
        end
        write_settings settings
        settings
      end

      def create_repo(repo_name)
        AwestructWebEditor::Repository.new({ :name => repo_name, :token => session[:github_auth], :username => session['username'] })
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
        json_return = repo.save_file path, params[:content]
        [200, json_return]

        # TODO: kick off rendering
        #retrieve_rendered_file(repo, path) unless ENV['RACK_ENV'] =~ /test/
      end

      def retrieve_rendered_file(repo, path)
        mapping_file = File.join(repo.base_repository_path, 'tmp', 'mapping.json')
        unless File.exists? mapping_file
          logger.info 'executing external script to render file'
          Bundler.with_clean_env do
            Open3.popen3("ruby exec_awestruct.rb --repo #{repo.name} --url '#{request.scheme}://#{request.host}:#{request.port}' --profile development --username '#{session['username']}'") do |_, stdout, stderr, _|
              errors = stderr.readlines.join
              logger.error "Error during rendering: #{errors}" unless errors.empty?
              return [500, "Error: #{path.to_s} not rendered"] unless errors.empty?
            end
          end
        end

        # Open mapping file
        #  find path
        #  check mtime
        #  (re)-generate if source file is newer than generated file
        #  Grab the generated file, return it and the content/type

        Bundler.with_clean_env do
          Open3.popen3("ruby exec_awestruct.rb --repo #{repo.name} --url '#{request.scheme}://#{request.host}:#{request.port}' --profile development --username '#{session['username']}'") do |_, stdout, stderr, _|
            mapping = {}
            stdout.each_line do |line|
              if line.match(/^\{.*/)
                mapping = JSON.load line
              end
            end
            errors = stderr.readlines.join
            logger.error "Error during rendering: #{errors}" unless errors.empty?

            # TODO: I need the encoding and content type as well

            if !mapping.nil? && mapping.include?('/' + path)
              [200, File.open(File.join(repo.base_repository_path, '_site', mapping['/' + path]), 'r') { |f| f.readlines }]
            else
              [500, "Error: #{path.to_s} not rendered"]
            end
          end
        end
      end

      def get_octokit_client(username)
        Octokit::Client.new(:login => username, :password => session['gh-pass'])
      end
    end
  end
end
