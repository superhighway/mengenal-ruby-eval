module SafeEvalr
  class Output
    attr_reader :text, :error_message

    def initialize(text, error_message, evalr)
      @text = text
      error_message = error_message.strip
      @error_message = error_message
      @success = !error_message && error_message.size <= 0
      @evalr = evalr
    end

    def success?
      @success
    end

    def eval_output
      @eval_output ||= @text + @error_message
    end

    def cache_and_return
      @evalr.cache_adapter.set(@evalr.cache_key, to_s)
      puts eval_output if @evalr.enable_eval_debug
      eval_output
    end

    def to_s
      eval_output
    end

    def self.create_from_popen(popen_output, evalr)
      stdin, stdout, stderr = popen_output
      error_message = stderr.readlines.join
      error_message.gsub!(/^?\s*\/[^:]*:/, " ruby:") if evalr.simplify_error_trace
      Output.new(stdout.readlines.join, error_message, evalr)
    end
  end
end
