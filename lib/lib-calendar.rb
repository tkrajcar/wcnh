require 'wcnh'

module Calendar

  class Event
    include Mongoid::Document
    field :id, type: Integer, default: lambda { Counters.next("calendar") }
    field :title, type: String
    field :desc, type: String
    field :date, type: DateTime
    field :creator, type: String
    field :groups, type: Array
  end

  class Group
    include Mongoid::Document
    field :title, type: String
    field :desc, type: String
    field :creator, type: String
    field :public, type: Boolean, default: true
    field :members, type: Array
  end

end
