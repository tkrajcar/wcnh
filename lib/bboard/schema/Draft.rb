require 'wcnh'

module BBoard

  class Draft
    include Mongoid::Document
    
    field :title, type: String
    field :body, type: String
    field :category_id, type: String
    field :parent_id, type: String, :default => nil # Posts that are threads belong to a parent post.
    
    embedded_in :user, :class_name => "BBoard::User"
  end

end
