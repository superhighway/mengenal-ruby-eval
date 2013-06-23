module Markaby
  class Builder
    alias_method :listing, :ul
    alias_method :item, :li

    def link name, url
      a(href: url, target: "_blank") { name }
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
