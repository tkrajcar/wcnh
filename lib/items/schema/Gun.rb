module Items

  class Gun < Weapon
    field :max_rounds, type: Integer, default: 0
    field :rounds, type: Integer, default: 0
  end

end