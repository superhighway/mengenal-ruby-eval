require_relative '../app'
require 'rspec'
require 'rack/test'

set :enable_eval_debug, false
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  Sinatra::Application
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.color_enabled = true
end
