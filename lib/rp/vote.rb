require 'wcnh'

module RP
  class Vote
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :voter, type: String
    
    embedded_in :item, :class_name => "RP::Item"
  end
end
