module Shiprace
  
  class Ship
    include Mongoid::Document
    
    field :name, type: String
    field :attr_speed, type: Integer, default: lambda { rand(5) + 2 }
    
    belongs_to :racer, :class_name => 'Shiprace::Racer' 
  end
  
end