module SafeEvalr
  class CobaRubyQuizEngine < PlainRubyEngine
    def challenge_paths(*args)
      if args.empty?
        @challenge_paths
      else
        @challenge_paths = args.first
      end
    end
  
    def next_challenge_hash
      challenge_index = @challenge_paths.index @input.challenge_path
      next_challenge_path = @challenge_paths[challenge_index+1] if challenge_index

      if next_challenge_path
        { next_challenge_path: next_challenge_path }
      else
        {}
      end
    end

    def safe_eval!(use_cache)
      challenge_path = @input.challenge_path
      capabilities = @input.capabilities
      is_correct = false
      output = ""
      popups = {}

      if (answer_path = Dir["answers/#{challenge_path}*"].first)
        answer_content = File.read(answer_path)
        if answer_path.end_with? ".rb"
          @input.snippet(@input.snippet + "\np #{answer_content}")
          output = super use_cache
          output_lines = output.lines
          is_correct = output_lines.last.strip == "true"
          output = output_lines[0...-1].join.strip
        else
          output = super use_cache
          is_correct = output.match(/(^|\s*|\A)#{Regexp.escape answer_content}\s*$/) != nil
        end
      else
        output = super use_cache
        if capabilities.include?("popups")
          delimiter = "#"*50
          outputs = output.split delimiter
          popups = outputs.last
          output = outputs[0...-1].join delimiter
          popups = JSON.parse(popups) if popups
        end
      end

      answer_hash = { is_correct: is_correct, output: output }.merge(popups)
      answer_hash.merge!(next_challenge_hash) if answer_hash[:is_correct]
      answer_hash.to_json
    end
  end
end
