require 'wcnh'

module Calendar

  class Event
    include Mongoid::Document
    field :id, type: Integer, :default => lambda {Counters.next("event")}
    index :id, :unique => true
    field :creator, type: String
    field :date, type: DateTime
    field :participants, type: Array
    field :location, type: String
    field :title, type: String
    field :info, type: String

    def self.add(creator, date, location, title, info)
      event = Event.create!(creator: creator, date: date, location: location, title: title, info: info)
    end

    def edit(params)
      params.each do |param, value|
        self.update_attribute(param, value)
      end
      self.save
    end

    def self.remove(id)
      Event.where(id: id).first.destroy
    end
  end

  class Group
    include Mongoid::Document
    field :name, type: String
    field :members, type: Array
    field :info, type: String
    field :public, type: Boolean, :default => true
  end

end


