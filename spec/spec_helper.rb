require 'rack'
require 'rack/test'
require 'sinatra'
require './app.rb'

APP = Rack::Builder.parse_file('config.ru').first

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    APP
  end

#  config.treat_symbols_as_metadata_keys_with_true_values = true
#  config.run_all_when_everything_filtered = true
#  config.filter_run :focus
end
