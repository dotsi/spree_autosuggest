Spree::BaseController.class_eval do
  after_filter :save_search
  #after_filter :clear_search_session

  def save_search
    keywords = @searcher.try :keywords

    if @products.present? && keywords.present? && !request.env["HTTP_USER_AGENT"].match(/\(.*https?:\/\/.*\)/)
      return if keywords.split(" ").size > 3
      query = Spree::Suggestion.find_or_initialize_by_keywords(keywords.downcase)

      query.items_found = (@searcher.sunspot && @searcher.sunspot.total ? @searcher.sunspot.total : @products.size)
      if query.count
        query.increment(:count)
      else
        query.count = 1
      end
      query.save
      session[:keywords] = keywords
    end
  end

  def clear_search_session
    if @product && session[:keywords]
      if query = Spree::Suggestion.find_by_keywords(session[:keywords].downcase)
        #zapisi product v data
      end
      session[:keywords] = nil
      #query.data = {}
    end
  end
end