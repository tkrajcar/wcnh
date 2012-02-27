require 'wcnh'

module RP
  class Item
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :num, type: Integer, :default => lambda {Counters.next("RP")}
    index :num, :unique => true
    field :title, type: String
    field :info, type: String
    field :creator, type: String
    field :votes, type: Integer, :default => 0
    field :sticky, type: Boolean, :default => false
    
    belongs_to :category, :class_name => "RP::Category"
  end
end
