module Items

  class Gun < Weapon
    field :max_rounds, type: Integer, default: 0
    field :rounds, type: Integer, default: 0
    field :ammunition, type: String 

    @showable = {mass: 'kg', damage: '', skill: '', ammunition: '', rounds: '', max_rounds: ''}
    @is_gun = true
  end

end