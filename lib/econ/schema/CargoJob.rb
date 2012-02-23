module Econ
  class CargoJob
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :commodity, :class_name => "Econ::Commodity"
    field :grade, :type => Integer, :default => 3
    field :expires, :type => DateTime
    field :claimed, :type => Boolean
    field :customer, :type => String
    field :size, :type => Integer
    field :price
    belongs_to :source, :class_name => "Econ::Location"
    belongs_to :destination, :class_name => "Econ::Location"


    def self.generate
      commodity = Econ::Commodity.all.to_a.shuffle.pop
      p "Commodity: #{commodity.name}"
      
      from_picklist = []
      commodity.demand_factors.where(:factor.gte => -1) .each do |from_system|
        from_picklist << {location: from_system.location, weighted_factor: rand(1.0..1.5) ** (1 + (from_system.factor + 2) / 5)}
      end
      from_picklist.sort! {|x,y| x[:weighted_factor] <=> y[:weighted_factor]}
      from = from_picklist.pop
      p "From: #{from[:location].name}"

      to_picklist = []
      to_list = commodity.demand_factors.where(:factor.lte => 1).where(:id.ne => from[:location]._id)
      if to_list.count == 0
        p "Couldn't find a destination system. Aborting."
        return
      end
      to_list.each do |to_system|
        to_picklist << {location: to_system.location, weighted_factor: rand(1.0..1.5) ** (1 + ((to_system.factor * -1) + 2) / 5)}
      end
      to_picklist.sort! {|x,y| x[:weighted_factor] <=> y[:weighted_factor]}
      to = to_picklist.pop
      p "To: #{to[:location].name}"

      grade = [1,1,2,2,3,3,4,5].shuffle[0]
      p "Grade: #{grade}"

      time_factor = [1,1,1,2,2,3,3,4,5].shuffle[0]
      p "Time factor: #{time_factor}"

      size = [rand(5..20),rand(20..100),rand(100..500)].shuffle[0]
      p "Size: #{size}"

      price = (10.0 * size * [1,commodity.price_volatility * (grade - 1)].max) ** (1.0 + time_factor / 10)
      p "Price: #{price}"
      if price < 1000
        p "Discarding <1000c job."
        CargoJob.generate
      end
    end
  end
end

