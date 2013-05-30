if popup_enabled && defined?(Popup)
  if (list = Popup.list) && !list.empty?
    puts "Lihat tab \"Popup\" di atas."
    puts("#"*50)
    puts JSON.generate({ popups: list })
  end
end
