module Econ
  class Distance
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :system_a, :class_name => "Space::System"
    belongs_to :system_b, :class_name => "Space::System"

    field :distance, :type => Integer, :default => 1
  end
end
