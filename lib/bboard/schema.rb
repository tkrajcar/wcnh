require 'wcnh'

module BBoard
  
  class User
    include Mongoid::Document
    
    identity :type => String
    # Reserve the user class instead of just pulling the dbref on the fly in case we want a place to store
    # global bboard user settings.
    
    embeds_many :subscriptions, :class_name => "BBoard::Subscription"
  end
  
  class Category
    include Mongoid::Document
    
    field :name, type: String
    field :permission_type, type: String 
    field :permission_value, type: String
    
    has_many :posts, :class_name => "BBoard::Post"
  end
  
  class Post
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :number, type: Integer, :default => lambda {Counters.next("BBPost")}
    index :number, :unique => true
    field :sticky, type: Boolean, :default => false
    field :author, type: String
    field :title, type: String
    field :body, type: String
    
    belongs_to :category, :class_name => "BBoard::Category"
  end
  
  class Subscription
    include Mongoid::Document
    
    field :category, type: String
    field :read_posts, type: Array
    
    embedded_in :user, :class_name => "BBoard::User"
  end
  
end
