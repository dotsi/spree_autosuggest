class Spree::SuggestionsController < Spree::BaseController
  caches_action :index, cache_path: Proc.new {|c| c.request.url }

  def index
    if Spree::Autosuggest::Config[:search_backend]
      suggestions = Spree::Config.searcher_class.new(keywords: params['term']).retrieve_products.map(&:name)
      suggestions = Spree::Product.search(name_cont: params['term']).result(distinct: true).map(&:name) if suggestions.blank?
    else
      suggestions =  Spree::Suggestion.find_by_fuzzy_keywords(params['term'],:limit => 4)   #Spree::Suggestion.relevant(params['term'])#.map(&:keywords)
    end
    products = Spree::Product.find_by_fuzzy_name(params['term'],:limit => 3) #Spree::Product.search(name_cont: params['term']).result(distinct: true).limit(5)
    taxons = Spree::Taxon.find_by_fuzzy_name(params['term'],:limit => 3) 

    tarr = []
    for t in taxons
      anc = []
      anc = t.ancestors.collect { |ancestor| ancestor.name } unless t.ancestors.empty?
      unless anc.empty?
        n = anc.join(" > ")+ " > "+ t.name
      else
        n = t.name
      end
      tarr << { :label => n, :link => spree.collections_path(t.permalink), :detail => false, :count => ""}
    end

    parr = []
    for p in products
      parr << { :label => p.name, :link => url_for(p), :image => (!p.images.empty? ? p.images.first.attachment.url(:mini) : ''), :detail => true }
    end
    suarr = []
    for sug in suggestions
      suarr << { :label => sug.keywords, :link => products_url(:keywords => sug.keywords), :count => sug.items_found || "", :detail => false }
    end
    if request.xhr?
      render json: suarr + tarr + parr #suggestions #+ parr
    else
      render_404
    end
  end
end
