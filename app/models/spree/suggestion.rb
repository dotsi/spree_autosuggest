class Spree::Suggestion < ActiveRecord::Base
  validates :keywords, presence: true

  attr_accessible :keywords, :items_found, :data, :count

  scope :has_data, where(["data is not ?", nil])

  #fuzzily_searchable :keywords

  def self.relevant(term)
    config = Spree::Autosuggest::Config

    select([:keywords, :items_found]).
      where("count >= ?", config.min_count).
      where("items_found != 0").
      where("keywords LIKE ? OR keywords LIKE ?", term + '%', term + '%').
      order("(#{config.count_weight}*count + #{config.items_found_weight}*items_found) DESC").
      limit(5)
  end
end
