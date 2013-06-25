require 'sinatra/asset_pipeline'
require "sinatra/base"
require "sinatra/json"
require 'multi_json'


class AwestructWebEditor < Sinatra::Base
  register Sinatra::AssetPipeline
  helpers Sinatra::JSON 

  get '/repo/:reponame' do

  end
end
