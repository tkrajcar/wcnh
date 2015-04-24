module Econ
  class Commodity
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :demand_factors, :class_name => "Econ::DemandFactor"

    field :name, :type => String
    field :lowercase_name, :type => String, :default => lambda { self.name.downcase }
    field :master_price, :type => Float
    field :price_volatility, :type => Float

    index :lowercase_name
  end
end
