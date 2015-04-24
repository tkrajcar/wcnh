require 'wcnh'

module RP
  class Category
    include Mongoid::Document
    
    field :name, type: String
    field :desc, type: String
    
    has_many :items, :class_name => "RP::Item"
  end
end
