module Econ
  class Distance
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :system_a, :class_name => "Space::System"
    belongs_to :system_b, :class_name => "Space::System"

    field :distance, :type => Integer, :default => 1

    def self.find_distance(a,b)
      loc_a = Econ::Location.where(space_object: a).first
      return "#-1" if loc_a.nil?
      sys_a = loc_a.system._id

      loc_b = Econ::Location.where(space_object: b).first
      return "#-1" if loc_b.nil?
      sys_b = loc_b.system._id

      d = Econ::Distance.where(system_a_id: sys_a).where(system_b_id: sys_b).first
      if d.nil?
        d = Econ::Distance.where(system_a_id: sys_b).where(system_b_id: sys_a).first
      end

      if d.nil?
        return "#-1"
      else
        return d.distance
      end
    end
  end
end
