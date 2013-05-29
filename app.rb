require 'sinatra'
require 'open3'
require 'digest/sha1'
require 'dalli'
require 'json'

set :challenge_paths, JSON.parse(File.read 'challenge_paths.json')["challenge_paths"]

if ENV["ENVIRONMENT"] == "heroku"
  set :simplify_error_trace, true
  set :enable_uglify_ruby, true
  set :enable_cache, true
  set :cache_adapter, Dalli::Client.new(ENV["MEMCACHIER_SERVERS"].split(","),
          {username: ENV["MEMCACHIER_USERNAME"],
           password: ENV["MEMCACHIER_PASSWORD"]})
  set :allowed_origins, %w{http://nyan.catcyb.org}
else
  simulate_heroku = false
  set :simplify_error_trace, simulate_heroku
  set :enable_uglify_ruby, simulate_heroku
  set :enable_cache, simulate_heroku
  set :cache_adapter, Dalli::Client.new('localhost:11211')
  set :allowed_origins, %w{http://localhost:4567}
end

def uglify_ruby(script)
  return script if !script || !settings.enable_uglify_ruby
  script.split("\n").join(";") + ";"
end

set :snippet_prefix, uglify_ruby(File.read('snippet_prefix.rb'))

def allowed_origin(server_name)
  if server_name
    server_name = server_name.to_s.strip
    return server_name if settings.allowed_origins.include?(server_name)
  end
end

def eval_snippet(snippet, load_fake_root=false)
  cache_key = Digest::SHA1.hexdigest(snippet)

  if settings.enable_cache && cached_output = settings.cache_adapter.get(cache_key)
    cached_output
  else
    file = Tempfile.new("mengenal-ruby-eval-#{Time.now.to_i}")
    eval_output = ''

    begin
      file.write settings.snippet_prefix + snippet
      file.rewind
      prefix = load_fake_root ? "FAKE_ROOT=1 " : ""
      stdin, stdout, stderr = Open3.popen3(prefix + "ruby #{file.path}")
      error_message = stderr.readlines.join
      error_message.gsub!(/^?\s*\/[^:]*:/, " ruby:") if settings.simplify_error_trace
      eval_output += stdout.readlines.join + error_message
    ensure
      file.close
      file.unlink
    end

    eval_output = eval_output.strip
    settings.cache_adapter.set(cache_key, eval_output)
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

def eval_snippet!(snippet, load_fake_root=false)
  validate_snippet! snippet
  eval_snippet snippet, load_fake_root
end

def should_load_fake_root(challenge_path)
  challenge_path.start_with?("05/") || challenge_path.start_with?("06/")
end

def generate_answer!(snippet, challenge_path)
  is_correct = false
  output = ""

  if (answer_path = Dir["answers/#{challenge_path}*"].first)
    answer_content = File.read(answer_path)
    if answer_path.end_with? ".rb"
      snippet += "\np #{answer_content}"
      output = eval_snippet! snippet, should_load_fake_root(challenge_path)
      output_lines = output.lines
      is_correct = output_lines.last.strip == "true"
      output = output_lines[0...-1].join.strip
    else
      output = eval_snippet! snippet, should_load_fake_root(challenge_path)
      is_correct = output.match(/(^|\s*|\A)#{Regexp.escape answer_content}$/) != nil
    end
  else
    output = eval_snippet! snippet, should_load_fake_root(challenge_path)
  end

  { is_correct: is_correct, output: output }
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

  answer_hash = generate_answer! params[:snippet], params[:challenge_path]
  challenge_index = settings.challenge_paths.index params[:challenge_path]
  next_challenge_path = settings.challenge_paths[challenge_index+1] if challenge_index

  if answer_hash[:is_correct] && next_challenge_path
    answer_hash.merge!(next_challenge_path: next_challenge_path)
  end

  answer_hash.to_json
end

