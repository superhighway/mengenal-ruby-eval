module Markaby
  class Builder
    def link name, url
      a(href: url, target: "_blank") { name }
    end

    def listing *args
      ul *args
    end

    def item *args
      li *args
    end
  end
end

class Popup
  LIST = []

  def self.kunjungi_link(url)
    LIST << { type: "CRURLResource", url: url }
  end

  def self.buat(&block)
    content = Markaby::Builder.new.div(&block).to_s
    LIST << { type: "CRHTMLContent", content: content }
  end

  def self.list
    LIST
  end
end
