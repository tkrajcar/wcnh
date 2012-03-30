require 'wcnh'

module BBoard
  
  class User
    include Mongoid::Document
    
    identity :type => String
    # Reserve the user class instead of just pulling the dbref on the fly in case we want a place to store
    # global bboard user settings.
    
    has_many :subscriptions, :class_name => "BBoard::Subscription"
  end
  
  class Post
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :sticky, type: Boolean, :default => false
    field :author, type: String
    field :title, type: String
    field :body, type: String
    field :parent_id , type: String # Posts that are threads belong to a parent post.
    field :old, type: Boolean, :default => false # Posts that timeout are invisible but archived
    
    belongs_to :category, :class_name => "BBoard::Category"
  end
  
  class Subscription
    include Mongoid::Document
    
    field :read_posts, type: Array
    
    belongs_to :user, :class_name => "BBoard::User"
    belongs_to :category, :class_name => "BBoard::Category"
  end
  
end
