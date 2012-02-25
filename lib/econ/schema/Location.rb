module Econ
  class Location
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :system, :class_name => "Space::System"
    has_many :demand_factors, :class_name => "Econ::DemandFactor"

    field :name, :type => String
    field :lowercase_name, :type => String, :default => lambda { self.name.downcase }
    field :space_object, :type => String

    index :lowercase_name
  end
end
