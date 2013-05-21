require 'sinatra'
require 'open3'
require 'digest/sha1'
require 'dalli'
require 'json'
require 'active_support'
require 'active_support/all'
require 'markaby'
require 'markaby/sinatra'


if ENV["ENVIRONMENT"] == "heroku"
  cache = Dalli::Client.new(ENV["MEMCACHIER_SERVERS"].split(","),
          {username: ENV["MEMCACHIER_USERNAME"],
           password: ENV["MEMCACHIER_PASSWORD"]})
  allowed_origins = %w{http://nyan.catcyb.org}
else
  cache = Dalli::Client.new('localhost:11211')
  allowed_origins = %w{http://localhost:4567}
end
DC = cache
ALLOWED_ORIGINS = allowed_origins
BLACKLIST_SCRIPT = "[:`, :exec, :system, :require].each {|m| Object.send(:undef_method, m)}; Object.send(:remove_const, :ENV);"
CHALLENGE_PATHS = JSON.parse(File.read 'challenge_paths.json')["challenge_paths"]

def allowed_origin(server_name)
  if server_name
    server_name = server_name.to_s.strip
    return server_name if ALLOWED_ORIGINS.include?(server_name)
  end
end

def eval_snippet(snippet)
  cache_key = Digest::SHA1.hexdigest(snippet)

  if cached_output = DC.get(cache_key)
    cached_output
  else
    file = Tempfile.new("mengenal-ruby-eval-#{Time.now.to_i}")
    eval_output = ''

    begin
      file.write BLACKLIST_SCRIPT + snippet
      file.rewind
      stdin, stdout, stderr = Open3.popen3("ruby -T3 #{file.path}")
      error_message = stderr.readlines.join
      error_message.gsub!(/^?\s*\/[^:]*:/, " ruby:")
      eval_output += stdout.readlines.join + error_message
    ensure
      file.close
      file.unlink
    end

    eval_output = eval_output.strip
    DC.set(cache_key, eval_output)
    eval_output
  end
end

def validate_snippet!(snippet)
  snippet_size = snippet.bytesize
  if snippet_size > 1048576
    halt 400, "Snippet is too long."
  elsif snippet_size <= 0
    halt 400, "Snippet is empty."
  end
end

def eval_snippet!(snippet)
  validate_snippet! snippet
  eval_snippet snippet
end




###################
### End Points
###################

post '/' do
  content_type 'text/plain'
  if server_name = allowed_origin(request.env["HTTP_ORIGIN"])
    headers['Access-Control-Allow-Origin'] = server_name
    headers['Access-Control-Allow-Methods'] = "POST"
  end

  eval_snippet! params[:snippet]
end

post '/coba-ruby.json' do
  content_type 'application/json'
  if server_name = allowed_origin(request.env["HTTP_ORIGIN"])
    headers['Access-Control-Allow-Origin'] = server_name
    headers['Access-Control-Allow-Methods'] = "POST"
  end

  output = eval_snippet! params[:snippet]
  is_correct = false #output == (File.read "answers/#{challenge_path}.txt")

  json_response =  {
    is_correct: is_correct,
    output: output
  }
  challenge_index = CHALLENGE_PATHS.index(params[:challenge_path])
  next_challenge_path = CHALLENGE_PATHS[challenge_index+1] if challenge_index
  if is_correct && next_challenge_path
    json_response.merge!(next_challenge_path: next_challenge_path)
  end
  json_response.to_json
end
