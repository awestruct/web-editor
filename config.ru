require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'slim'
require 'awestruct/rack/app'

require File.join(File.dirname(__FILE__), 'app.rb')

set :run, false
set :raise_errors, true

map '/assets' do
  run AwestructWebEditor::App.sprockets
end

map '/font' do
  run AwestructWebEditor::App.sprockets
end

run AwestructWebEditor::App
