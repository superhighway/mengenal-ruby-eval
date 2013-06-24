require 'sinatra'
require 'open3'
require 'digest/sha1'
require 'dalli'
require 'json'
require_relative 'lib/safe_evalr'

set :challenge_paths, JSON.parse(File.read 'challenge_paths.json')["challenge_paths"]

if ENV["ENVIRONMENT"] == "heroku"
  set :simplify_error_trace, true
  set :enable_uglify_ruby, true
  set :enable_cache, true
  set :cache_adapter, Dalli::Client.new(ENV["MEMCACHIER_SERVERS"].split(","),
          {username: ENV["MEMCACHIER_USERNAME"],
           password: ENV["MEMCACHIER_PASSWORD"]})
  set :allowed_origins, %w{http://nyan.catcyb.org http://id-ruby.org}
  set :enable_eval_debug, false
else
  simulate_heroku = false
  set :simplify_error_trace, simulate_heroku
  set :enable_uglify_ruby, simulate_heroku
  set :enable_cache, simulate_heroku
  set :cache_adapter, Dalli::Client.new('localhost:11211')
  set :allowed_origins, %w{http://localhost:4567}
  set :enable_eval_debug, true
end

def uglify_ruby(script)
  return script if !script || !settings.enable_uglify_ruby
  script.split("\n").join(";") + ";"
end

set :snippet_prefix, uglify_ruby(File.read('snippet_prefix.rb'))
set :popup_response_generator, uglify_ruby(File.read('popup_response_generator.rb'))

def allowed_origin(server_name)
  if server_name
    server_name = server_name.to_s.strip
    return server_name if settings.allowed_origins.include?(server_name)
  end
end

before do
  if server_name = allowed_origin(request.env["HTTP_ORIGIN"])
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = "POST"
  end
end

post '/' do
  begin
    opts = params
    eng = SafeEvalr::PlainRubyEngine.new do
      snippet_prefix  settings.snippet_prefix
      snippet         opts[:snippet]
    end

    eng.configure do
      cache_adapter         settings.cache_adapter
      enable_eval_debug     settings.enable_eval_debug
      simplify_error_trace  settings.simplify_error_trace
    end

    content_type 'text/plain'
    eng.safe_eval! settings.enable_cache
  rescue SafeEvalr::Error => e
    halt 400, e.message
  end
end

post '/coba-ruby.json' do
  begin
    opts = params
    eng = SafeEvalr::CobaRubyQuizEngine.new do
      snippet_prefix  settings.snippet_prefix
      snippet         opts[:snippet]
      challenge_path  opts[:challenge_path]
      capabilities    opts[:capabilities]
    end

    eng.configure do
      challenge_paths       settings.challenge_paths
      cache_adapter         settings.cache_adapter
      enable_eval_debug     settings.enable_eval_debug
      simplify_error_trace  settings.simplify_error_trace
    end

    content_type 'application/json'
    eng.safe_eval! settings.enable_cache
  rescue SafeEvalr::Error => e
    content_type 'text/plain'
    halt 400, e.message
  end
end

