require "sinatra/base"
require "sinatra/json"

class MyApp < Sinatra::Base
  helpers Sinatra::JSON 
end
