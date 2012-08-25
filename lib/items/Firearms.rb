module Items
  module Firearms
    def reload(ammo)
      return [false, :invalid_gun] unless self.is_gun
      return [false, :full_gun] unless self.attribs['rounds'] < self.attribs['max_rounds']
      return [false, :invalid_ammo] unless ammo.kind.class.name.split('::').last == "Ammunition"
      return [false, :incompatible_ammo] unless self.attribs['ammunition'] == ammo.attribs['name']
      return [false, :insufficient_ammo] unless ammo.attribs['amount'] > 0
      
      if (ammo.attribs['amount'] < (amount = self.attribs['max_rounds'] - self.attribs['rounds']))
        self.attribs['rounds'] += ammo.attribs['amount']
        Items.remove(Items::MUSH_FUNCTIONS, ammo)
      else
        self.attribs['rounds'] = self.attribs['max_rounds']
        ammo.attribs['amount'] -= amount
        ammo.save
      end
      
      self.save
      
      return [true, amount]
    end
  end
end