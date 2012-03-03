require 'wcnh'

module Anatomy
  
  class Part
    include Mongoid::Document
    
    field :mass, type: Float, :default => 0
    field :pctHealth, type: Float, :default => 1.0
    field :name, type: String, :default => lambda { self.name.split(":").last }
    
    embedded_in :body, :class_name => "Anatomy::Body"
  end
  
end
