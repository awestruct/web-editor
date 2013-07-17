require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'slim'
require 'sass'
require 'compass'
require 'uglifier'

require File.join(File.dirname(__FILE__), 'app.rb')

set :run, false
set :raise_errors, true

map '/assets' do
  run AwestructWebEditor::PublicApp.sprockets
end

run AwestructWebEditor::SecureApp
