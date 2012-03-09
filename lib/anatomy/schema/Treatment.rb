require 'wcnh'

module Anatomy
  
  class Treatment
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :healer, type: String
    field :level, type: String
    
    embeds_one :target, :class_name => "Anatomy::Part"
    
  end
end
