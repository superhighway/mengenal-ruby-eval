require 'sinatra'
require 'open3'
require 'digest/sha1'
require 'dalli'


if ENV["MEMCACHIER_SERVERS"]
  cache = Dalli::Client.new(ENV["MEMCACHIER_SERVERS"].split(","),
          {username: ENV["MEMCACHIER_USERNAME"],
           password: ENV["MEMCACHIER_PASSWORD"]})
  allowed_origin = "http://nyan.catcyb.org"
else
  cache = Dalli::Client.new('localhost:11211')
  allowed_origin = "http://localhost:4567"
end
DC = cache
ALLOWED_ORIGIN = allowed_origin

post '/' do
  content_type 'text/plain'
  headers['Access-Control-Allow-Origin'] = ALLOWED_ORIGIN
  headers['Access-Control-Allow-Methods'] = "POST"
  snippet = params[:snippet]

  snippet_size = snippet.bytesize
  if snippet_size > 1048576
    halt 400, "Snippet is too long."
  elsif snippet_size <= 0
    halt 400, "Snippet is empty."
  end

  cache_key = Digest::SHA1.hexdigest(snippet)

  if cached_output = DC.get(cache_key)
    cached_output
  else
    file = Tempfile.new("mengenal-ruby-eval-#{Time.now.to_i}")
    eval_output = ''

    begin
      file.write snippet
      file.rewind
      stdin, stdout, stderr = Open3.popen3("ruby -T3 #{file.path}")
      error_message = stderr.readlines.join
      error_message.gsub!(/^\/[^:]*:/, "mengenal-ruby:")
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

