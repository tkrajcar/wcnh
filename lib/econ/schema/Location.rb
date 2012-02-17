module Econ
  class Location
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :system, :class_name => "Space::System"
    field :name, :type => String
    field :lowercase_name, :type => String, :default => lambda { self.name.downcase }
  end
end
