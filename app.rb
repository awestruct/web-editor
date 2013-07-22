require 'sinatra/base'
require 'json'
require 'rack'
require 'rack/ssl'
require 'octokit'
require 'uri'

require_relative 'helpers/link'
require_relative 'public_app'

module AwestructWebEditor
  class SecureApp < Sinatra::Base
    set :ssl, lambda { |_| development? }

    use AwestructWebEditor::PublicApp
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

    get '/settings' do
      [200, JSON.dump(read_settings)]
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
      def settings_storage_file
        base = ENV['RACK_ENV'] =~ /test/ ? 'tmp/repos' : 'repos'
        File.join(base, 'github-settings')
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
