require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'slim'
require 'uglifier'
require 'sprockets'
require 'sprockets-sass'
require 'sprockets-helpers'
require 'sass'
require 'compass'
require 'zurb-foundation'

require File.join(File.dirname(__FILE__), 'public_app.rb')

if ENV['OPENSHIFT_DATA_DIR']
  ENV['RACK_ENV'] = 'production'
end

set :run, false
set :raise_errors, true

map '/assets' do
  sprockets = Sprockets::Environment.new 
  sprockets.css_compressor = :scss
  Sprockets::Sass.options[:output_style] = (ENV['RACK_ENV'] == 'production') ? :compressed : :expanded
  %w(sass javascripts images fonts).each do |dir|
    sprockets.append_path File.join('assets', dir)
  end
  if ENV['RACK_ENV'] == 'production'
    sprockets.prepend_path File.join('public', 'font')
    sprockets.prepend_path File.join('public', 'stylesheets')
    sprockets.prepend_path File.join('public', 'javascripts')
    sprockets.prepend_path File.join('public', 'images')
    sprockets.index 
  end
  run sprockets
end

run AwestructWebEditor::PublicApp
