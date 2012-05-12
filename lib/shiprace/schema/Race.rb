module Shiprace
  
  class Race
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :order, type: Array, default: []
    field :completed, type: Boolean, default: false
    
    has_and_belongs_to_many :racers, :class_name => "Shiprace::Racer"
    has_many :tickets, :class_name => 'Shiprace::Ticket'
  end
  
end