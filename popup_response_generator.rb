if popup_enabled && defined?(Popup)
  if (list = Popup.list) && !list.empty?
    puts("#"*50)
    puts JSON.generate({ popups: list })
  end
end
