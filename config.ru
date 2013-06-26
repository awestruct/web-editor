require "rubygems"
require "bundler/setup"
require "sinatra"
require "slim"
require './app'
 
set :run, false
set :raise_errors, true

map '/assets' do
  run AwestructWebEditor.sprockets
end 

map '/font' do
  run AwestructWebEditor.sprockets
end 

run AwestructWebEditor
