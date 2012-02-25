require 'wcnh'

module RP
  class Category
    include Mongoid::Document
    
    field :title, type: String
    
    has_many :items, :class_name => "RP::Item"
  end
end
