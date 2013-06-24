module SafeEvalr
  class PlainRubyEngine
    def initialize(&block)
      @input = Input.new
      @input.instance_eval &block
    end

    def cache_key
      @input.cache_key
    end
    
    def configure &block
      self.instance_eval &block
    end

    def cache_adapter(*args)
      if args.empty?
        @cache_adapter
      else
        @cache_adapter = args.first
      end
    end

    def enable_eval_debug(*args)
      if args.empty?
        @enable_eval_debug
      else
        @enable_eval_debug = args.first
      end
    end

    def simplify_error_trace(*args)
      if args.empty?
        @simplify_error_trace
      else
        @simplify_error_trace = args.first
      end
    end

    def safe_eval!(use_cache)
      @input.validate!

      if use_cache && cached_output = @cache_adapter.get(cache_key)
        cached_output
      else
        if output = safe_eval
          output
        else
          raise EvalError
        end
      end
    end

    private
    def safe_eval
      file = Tempfile.new("mengenal-ruby-eval-#{Time.now.to_i}")
      output = nil

      begin
        safe_snippet = @input.safe_snippet
        puts safe_snippet if enable_eval_debug
        file.write safe_snippet
        file.rewind

        output = Output.create_from_popen Open3.popen3(@input.capabilities_env + "ruby #{file.path}"), self
      ensure
        file.close
        file.unlink
      end

      output ? output.cache_and_return : nil
    end
  end
end
