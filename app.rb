require "sinatra/base"
require "sinatra/json"
require 'multi_json'

class AwestructWebEditor < Sinatra::Base
  helpers Sinatra::JSON 

  get '/repo/:reponame' do

  end
end
