module SafeEvalr
  class Input
    def snippet_prefix(*args)
      if args.empty?
        @snippet_prefix
      else
        @cache_key = nil
        @safe_snippet = nil
        @snippet_prefix = args.first
      end
    end

    def snippet(*args)
      if args.empty?
        @snippet
      else
        @cache_key = nil
        @safe_snippet = nil
        @snippet = args.first
      end
    end

    def challenge_path(*args)
      if args.empty?
        @challenge_path
      else
        @challenge_path = args.first
      end
    end

    def capabilities(*args)
      if args.empty?
        @capabilities = Set.new unless @capabilities
        @capabilities
      else
        @cache_key = nil
        @safe_snippet = nil
        @capabilities = Set.new args.first
      end
    end

    def safe_snippet
      return @safe_snippet if @safe_snippet

      @safe_snippet = @snippet
      @safe_snippet = [@snippet, settings.popup_response_generator].join("\n") if capabilities.include?("popups")
      @safe_snippet = @snippet_prefix + @safe_snippet
      @safe_snippet
    end

    def cache_key
      @cache_key ||= Digest::SHA1.hexdigest(safe_snippet)
    end
    
    def capabilities_env
      (@capabilities || []).map { |c| c.upcase + "=1 " }.join
    end

    def validate!
      snippet_size = @snippet.bytesize
      if snippet_size > 1048576
        raise BytesizeLimitError
      elsif snippet_size <= 0
        raise EmptyError
      end
    end
  end
end
