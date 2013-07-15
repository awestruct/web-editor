require 'sinatra/base'
require 'sinatra/json'
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
    register Sinatra::Sprockets::Helpers

    use AwestructWebEditor::PublicApp
    use Rack::SSL, :exclude => lambda { |env| development? }

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
      write_settings JSON.load params['settings']
    end

    put '/settings' do
      settings = JSON.load params['settings']
      get_github_token settings
      AwestructWebEditor::Repository.new({ :name => URI(settings['repo']).path.split('/').last }).clone
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
        client = Octokit::Client.new(:login => settings['username'], :password => settings['password'])
        result = client.create_authorization :note => 'Awestruct Web Editor', :scopes => ['repo']
        settings.delete('password')
        settings['oauth_token'] = result['token']
        settings['client_id'] = result['client_id']

        write_settings settings
      end
    end
  end
end
