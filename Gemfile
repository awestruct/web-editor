source 'https://rubygems.org'

# Gems for the main application
gem 'sinatra', '~> 1.4.3'
gem 'sinatra-contrib', '~> 1.4'
gem 'slim', '~> 2.0', :require => false
gem 'zurb-foundation', '~> 4.2'
gem 'rake', '~> 10'
gem 'multi_json', '~> 1.7'

# Gems related to the use of awestruct
group :awestruct do
  gem 'awestruct', '~> 0.5.2'

  # Markup and templates
  gem 'haml', '~> 4.0.2', :require => false
  gem 'kramdown', '~> 1.0.2', :require => false
  gem 'asciidoctor', '~> 0.1.3', :require => false
  gem 'RedCloth', '~> 4.2.9', :require => false 
  gem 'github-markup', '~> 0.7.5', :require => false
  gem 'redcarpet', '~> 2.3.0', :require => false

  # CSS frameworks
  gem 'bootstrap-sass', '~> 2.3', :require => false 

end 

group :developement do
  gem 'rspec', '~> 2.13'
  gem 'guard', '~> 1.8'
  gem 'guard-rspec', '~> 3.0'
  gem 'rack-test', '~> 0.6'
  gem 'puma', '~> 2.1', :require => false # I like puma and it runs everywhere
  gem 'sinatra-asset-pipeline', '~> 0.2'
end
