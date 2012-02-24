Space::System.delete_all
Econ::Location.delete_all
Econ::Commodity.delete_all
Econ::DemandFactor.delete_all
Econ::Distance.delete_all

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

sting = midgard_system.locations.create!(name: "Sting")
vespus_i = vespus_system.locations.create!(name: "Vespus I")
cabrea_ii = cabrea_system.locations.create!(name: "Cabrea II")
inferno = pembroke_system.locations.create!(name: "Inferno")

live_animals = Econ::Commodity.create!(name: "live animals", master_price: 20, price_volatility: 2)
live_animals.demand_factors.create!(location: sting, factor: 2)
live_animals.demand_factors.create!(location: vespus_i, factor: 1)
live_animals.demand_factors.create!(location: cabrea_ii, factor: -1)
live_animals.demand_factors.create!(location: inferno, factor: 0)

meat_products = Econ::Commodity.create!(name: "meat", master_price: 10, price_volatility: 1)
meat_products.demand_factors.create!(location: sting.id, factor: 1)
meat_products.demand_factors.create!(location: vespus_i, factor: -1)
meat_products.demand_factors.create!(location: cabrea_ii, factor: 1)
meat_products.demand_factors.create!(location: inferno, factor: 1)

toys = Econ::Commodity.create!(name: "toys", master_price: 100, price_volatility: 3)
toys.demand_factors.create!(location: vespus_i, factor: -1)
toys.demand_factors.create!(location: cabrea_ii, factor: 1)


