module Items

  class Gun < Weapon
    field :max_rounds, type: Integer, default: 0
    field :rounds, type: Integer, default: 0
    field :ammunition, type: String 

    @showable = {mass: 'kg', damage: '', skill: '', ammunition: ''}
    @is_gun = true
    
    def self.reload(gun, ammo)
      return [false, :invalid_gun] unless gun.is_gun
      return [false, :full_gun] unless gun.attribs['rounds'] < gun.attribs['max_rounds']
      return [false, :invalid_ammo] unless ammo.kind.class.name.split('::').last == "Ammunition"
      return [false, :incompatible_ammo] unless gun.attribs['ammunition'] == ammo.attribs['name']
      return [false, :insufficient_ammo] unless ammo.attribs['amount'] > 0
      return true
    end
  end

end