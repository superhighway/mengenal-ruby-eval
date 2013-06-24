module SafeEvalr
  class Error < StandardError
  end

  class BytesizeLimitError < Error
    def initialize(msg="Ups error... Kodenya kepanjangan. Kurangin yah... Thx :)")
      super msg
    end
  end

  class EmptyError < Error
    def initialize(msg="Ups error... Kodenya kosong. Ketik sesuatu dong... Thx yah :)")
      super msg
    end
  end

  class EvalError < Error
    def initialize(msg="Ups error... Gagal eval codenya nih... Kontak thecatcyborg@gmail.com yah...")
      super msg
    end
  end
end