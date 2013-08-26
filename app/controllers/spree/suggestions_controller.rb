class Spree::SuggestionsController < Spree::BaseController
  ssl_allowed :index
  caches_action :index, cache_path: Proc.new {|c| c.request.url }

  def index
    require 'blurrily/client'
    #if Spree::Autosuggest::Config[:search_backend]
    #  suggestions = Spree::Config.searcher_class.new(keywords: params['term']).retrieve_products.map(&:name)
    #  suggestions = Spree::Product.search(name_cont: params['term']).result(distinct: true).map(&:name) if #suggestions.blank?
    #else
    #  sclient = Blurrily::Client.new(host: '127.0.0.1', port: 12021, db_name: 'suggestions')
    #  suggestions = Spree::Suggestion.find(sclient.find(params['term'], 4)) #Spree::Suggestion.#find_by_fuzzy_keywords(params['term'],:limit => 4)   #Spree::Suggestion.relevant(params['term'])#.map(#&:keywords)
    #end
    sclient = Blurrily::Client.new(host: '127.0.0.1', port: 12021, db_name: 'suggestions')
    ids = sclient.find(params['term'], 4)
    suggestions = []
    if ids != []
      suggestions = Spree::Suggestion.where(:id => ids).order("field(id, #{ids.join(',')})") #Spree::Suggestion.find_all_by_id(ids, :order => "field(id, #{ids.join(',')})")
    end
    pclient = Blurrily::Client.new(host: '127.0.0.1', port: 12021, db_name: 'products') 
    pids = pclient.find(params['term'], 4)   
    products = []    
    if pids != []
      products = Spree::Product.where(:id => pids).order("field(id, #{pids.join(',')})") #Spree::Product.find_all_by_id(pids, :order => "field(id, #{pids.join(',')})")
    end
    tclient = Blurrily::Client.new(host: '127.0.0.1', port: 12021, db_name: 'taxons')
    tids = tclient.find(params['term'], 3)
    taxons = []
    if tids != []
      taxons = Spree::Taxon.where(:id => tids).order("field(id, #{tids.join(',')})") #Spree::Taxon.find_all_by_id(tids, :order => "field(id, #{tids.join(',')})")
    end
    #tclient = Blurrily::Client.new(host: '127.0.0.1', port: 12021, db_name: 'taxons')
    #pclient = Blurrily::Client.new(host: '127.0.0.1', port: 12021, db_name: 'products')
    #products = Spree::Product.find(pclient.find(params['term'], 3)) #Spree::Product.find_by_fuzzy_name(params[#'term'],:limit => 3) #Spree::Product.search(name_cont: params['term']).result(distinct: true).limit(5)
    #taxons = Spree::Taxon.find(tclient.find(params['term'], 4))#Spree::Taxon.find_by_fuzzy_name(params['term']#,:limit => 3) 

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
      parr << { :label => p.name, :link => url_for(p), :image => (!p.images.empty? ? p.images.first.attachment.url(:mini) : ''), :detail => true } if p.active?
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
