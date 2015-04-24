require 'wcnh'

module BBoard
  
  class User
    include Mongoid::Document
    
    identity :type => String
    # Reserve the user class instead of just pulling the dbref on the fly in case we want a place to store
    # global bboard user settings.
    
    has_many :subscriptions, :class_name => "BBoard::Subscription"
    embeds_one :draft, :class_name => "BBoard::Draft"
  end
  
end
