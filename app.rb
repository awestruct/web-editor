require 'sinatra/base'
require 'json'
require 'rack'
require 'rack/ssl'
require 'octokit'
require 'uri'
require 'digest/sha2'
require 'sinatra/cookies'
require 'securerandom'

require_relative 'helpers/link'
require_relative 'public_app'

module AwestructWebEditor
  class SecureApp < Sinatra::Base
    set :ssl, lambda { |_| development? }
    enable :sessions

    use Rack::SSL, :exclude => lambda { |_| development? }

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
      also_reload 'app.rb'
      also_reload 'helpers/**/*.rb'
      also_reload 'public_app.rb'
      set :raise_errors, true
      enable :logging, :dump_errors, :raise_errors
    end

    before do
      unless session['token']
        session['token'] = Digest::SHA512.new << SecureRandom.uuid << SecureRandom.random_bytes
      end

      # check the token they have sent
      if cookies['token']
        request_token = env['token']
        request_time = env['time']
        unless request_token == Digest::SHA512.new << "#{session['token']}#{request_time}"
          halt 401
        end
      else
        cookies['token'] = Digest::SHA512.new << "#{session['token']}"
      end
    end

    after do
      time = DateTime.now.iso8601
      response.headers['time'] = time
      response.headers['token'] = Digest::SHA512.new << "#{session['token']}#{time}"
    end

    use AwestructWebEditor::PublicApp
    get '/settings' do
      [200, JSON.dump(read_settings.reject { |k,v| /oauth|client/ =~ k})]
    end

    post '/settings' do
      settings = { 'repo' => params['repo'], 'username' => params['username'], 'password' => params['password'] }
      write_settings settings
    end

    put '/settings' do
      settings = { 'repo' => params['repo'], 'username' => params['username'], 'password' => params['password'] }
      get_github_token settings
      clone_result = AwestructWebEditor::Repository.new({ :name => URI(settings['repo']).path.split('/').last }).clone
      if clone_result.first != 0
        [500, clone_result[1]]
      else
        [200, 'Successfully cloned']
      end
    end

    error do
      "An error occurred while processing: #{env['sinatra.error'].name}. Message: #{env['sinatra.error'].message}"
    end

    helpers do
      include Sinatra::Cookies

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
            JSON.load(f)
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
        # TODO check for an oauth token already, use that if it returns, eventually we'll need to use https://github.com/atmos/sinatra_auth_github
        client = Octokit::Client.new(:login => settings['username'], :password => settings['password'])
        result = client.create_authorization :note => 'Awestruct Web Editor', :scopes => ['repo']
        settings.delete('password')
        settings['oauth_token'] = result['token']
        settings['client_id'] = result['app']['client_id']

        write_settings settings
      end
    end
  end
end
