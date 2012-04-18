require 'wcnh'

module BBoard

  class Post
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Paranoia # Use paranoia to archive posts that are deleted or timed out. 
    
    field :sticky, type: Boolean, :default => false
    field :author, type: String
    field :title, type: String
    field :body, type: String
    field :parent_id, type: String, :default => nil # Posts that are threads belong to a parent post.
    index :parent_id
    
    belongs_to :category, :class_name => "BBoard::Category", :index => true

    validates_presence_of :title, message: "Posts must have a title."

    validates_presence_of :body, message: "Posts cannot be empty."    
  end

end
