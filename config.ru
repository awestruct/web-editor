require "rubygems"
require "bundler/setup"
require "sinatra"
require "slim"
require './app'
 
set :run, false
set :raise_errors, true
set :public_dir, 'public'

run AwestructWebEditor
