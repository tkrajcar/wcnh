require 'wcnh'

module Calendar

  class Event
    include Mongoid::Document
    field :num, type: Integer, :default => lambda {Counters.next("event")}
    index :num, :unique => true
    field :creator, type: String
    field :date, type: DateTime
    field :participants, type: Array, :default => []
    field :location, type: String
    field :title, type: String
    field :info, type: String
  end

  class Group
    include Mongoid::Document
    field :name, type: String
    field :members, type: Array
    field :info, type: String
    field :public, type: Boolean, :default => true
  end

end


