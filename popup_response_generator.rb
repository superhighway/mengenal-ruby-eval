if popup_enabled && defined?(Popup)
  if (list = Popup.list) && !list.empty?
    puts "Lihat tab \"Popup\"."
    puts("#"*50)
    puts JSON.generate({ popups: list })
  end
end
