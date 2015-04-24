require File.expand_path('../../lib/wcnh.rb', __FILE__)
require 'csv'

Space::System.delete_all
Econ::Location.delete_all
Econ::Commodity.delete_all
Econ::DemandFactor.delete_all
Econ::Distance.delete_all
Econ::CargoJob.delete_all

midgard_system = Space::System.create!(name: "Midgard")
vespus_system = Space::System.create!(name: "Vespus")
pembroke_system = Space::System.create!(name: "Pembroke")
cabrea_system = Space::System.create!(name: "Cabrea")

Econ::Distance.create!(system_a: cabrea_system, system_b: pembroke_system, distance: 3)
Econ::Distance.create!(system_a: cabrea_system, system_b: midgard_system, distance: 4)
Econ::Distance.create!(system_a: cabrea_system, system_b: vespus_system, distance: 3)
Econ::Distance.create!(system_a: pembroke_system, system_b: midgard_system, distance: 5)
Econ::Distance.create!(system_a: pembroke_system, system_b: vespus_system, distance: 1)
Econ::Distance.create!(system_a: midgard_system, system_b: vespus_system, distance: 5)

sting = midgard_system.locations.create!(name: "Sting", space_object: "#331")
vespus_i = vespus_system.locations.create!(name: "Vespus I", space_object: "#170")
cabrea_ii = cabrea_system.locations.create!(name: "Cabrea II", space_object: "#126")
inferno = pembroke_system.locations.create!(name: "Inferno", space_object: "#150")

CSV.foreach("data/commodities.csv") do |row|
  commod = Econ::Commodity.create!(name: row[0].downcase, master_price: row[1], price_volatility: row[6])
  i = 2
  [sting, vespus_i, cabrea_ii, inferno].each do |location|
    if row[i] == 'none'
      p "Skipping #{commod.name} demand factor for #{location.name}."
      i = i + 1
      next
    end
    commod.demand_factors.create!(location: location, factor: row[i])
    i = i + 1
  end
end
