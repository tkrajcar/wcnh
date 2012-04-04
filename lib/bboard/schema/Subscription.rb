require 'wcnh'

module BBoard
  
  class Subscription
    include Mongoid::Document
    
    field :read_posts, type: Array, :default => []
    
    belongs_to :user, :class_name => "BBoard::User"
    belongs_to :category, :class_name => "BBoard::Category"
  end
  
end
