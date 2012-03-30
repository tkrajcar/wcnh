require 'wcnh'

module BBoard
  
  class User
    include Mongoid::Document
    
    identity :type => String
    # Reserve the user class instead of just pulling the dbref on the fly in case we want a place to store
    # global bboard user settings.
    
    has_many :subscriptions, :class_name => "BBoard::Subscription"
  end
   
  class Subscription
    include Mongoid::Document
    
    field :read_posts, type: Array
    
    belongs_to :user, :class_name => "BBoard::User"
    belongs_to :category, :class_name => "BBoard::Category"
  end
  
end
