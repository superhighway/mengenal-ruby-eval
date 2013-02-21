require 'sinatra'
require 'open3'
require 'digest/sha1'
require 'dalli'

DC = Dalli::Client.new('localhost:11211')

post '/' do
  content_type 'text/plain'
  command = params[:command]

  if command.bytesize > 1048576
    halt 400, "Command is too long."
  end

  cache_key = Digest::SHA1.hexdigest(command)

  if cached_output = DC.get(cache_key)
    cached_output
  else
    file = Tempfile.new("mengenal-ruby-eval-#{Time.now.to_i}")
    eval_output = ''

    begin
      file.write command
      file.rewind
      stdin, stdout, stderr = Open3.popen3("ruby #{file.path}")
      eval_output += stdout.readlines.join + stderr.readlines.join
    ensure
      file.close
      file.unlink
    end

    eval_output = eval_output.strip
    DC.set(cache_key, eval_output)
    eval_output
  end
end

