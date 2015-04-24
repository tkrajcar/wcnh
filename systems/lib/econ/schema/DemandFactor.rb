module Econ
  class DemandFactor
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :commodity, :class_name => "Econ::Commodity"
    belongs_to :location, :class_name => "Econ::Location"
    field :factor, :type => Float
  end
end
