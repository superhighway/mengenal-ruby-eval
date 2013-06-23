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

def validate_snippet!(snippet)
  snippet_size = snippet.bytesize
  if snippet_size > 1048576
    halt 400, "Ups error... Kodenya kepanjangan. Kurangin yah... Thx :)"
  elsif snippet_size <= 0
    halt 400, "Ups error... Kodenya kosong. Ketik sesuatu dong... Thx yah :)"
  end
end

def eval_snippet!(snippet, capabilities=[])
  validate_snippet! snippet
  cache_key = Digest::SHA1.hexdigest(snippet)

  if settings.enable_cache && cached_output = settings.cache_adapter.get(cache_key)
    cached_output
  else
    file = Tempfile.new("mengenal-ruby-eval-#{Time.now.to_i}")
    eval_output = ''

    begin
      snippet = [snippet, settings.popup_response_generator].join("\n") if capabilities.include?("popups")
      snippet = settings.snippet_prefix + snippet
      puts snippet if settings.enable_eval_debug
      file.write snippet
      file.rewind
      prefix = capabilities.map { |c| c.upcase + "=1 " }.join
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
    puts eval_output if settings.enable_eval_debug
    eval_output
  end
end

def generate_answer!(params)
  snippet = params[:snippet]
  challenge_path = params[:challenge_path]
  capabilities = Set.new params[:capabilities]
  is_correct = false
  output = ""
  popups = {}

  if (answer_path = Dir["answers/#{challenge_path}*"].first)
    answer_content = File.read(answer_path)
    if answer_path.end_with? ".rb"
      snippet += "\np #{answer_content}"
      output = eval_snippet! snippet, capabilities
      output_lines = output.lines
      is_correct = output_lines.last.strip == "true"
      output = output_lines[0...-1].join.strip
    else
      output = eval_snippet! snippet, capabilities
      is_correct = output.match(/(^|\s*|\A)#{Regexp.escape answer_content}\s*$/) != nil
    end
  else
    output = eval_snippet! snippet, capabilities
    if capabilities.include?("popups")
      delimiter = "#"*50
      outputs = output.split delimiter
      popups = outputs.last
      output = outputs[0...-1].join delimiter
      popups = JSON.parse(popups) if popups
    end
  end

  { is_correct: is_correct, output: output }.merge(popups)
end



###################
### End Points
###################

before do
  if server_name = allowed_origin(request.env["HTTP_ORIGIN"])
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = "POST"
  end
end

post '/' do
  content_type 'text/plain'
  eval_snippet! params[:snippet]
end

post '/coba-ruby.json' do
  content_type 'application/json'

  answer_hash = generate_answer! params
  challenge_index = settings.challenge_paths.index params[:challenge_path]
  next_challenge_path = settings.challenge_paths[challenge_index+1] if challenge_index

  if answer_hash[:is_correct] && next_challenge_path
    answer_hash.merge!(next_challenge_path: next_challenge_path)
  end

  answer_hash.to_json
end

