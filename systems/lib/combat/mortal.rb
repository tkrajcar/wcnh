module Combat
  def self.reload(enactor, gun, ammo)
    return "> ".bold.red + "That's not a valid weapon." unless gun = Items::Instance.where(dbref: gun).first
    return "> ".bold.red + "That's not valid ammunition." unless ammo = Items::Instance.where(dbref: ammo).first
    
    result = gun.reload(ammo)
    
    if !result.first 
      case result.last
      when :invalid_gun
        return "> ".bold.red + "The #{gun.attribs['name']} is not a valid gun."
      when :full_gun
        return "> ".bold.red + "The #{gun.attribs['name']} is already fully loaded."
      when :invalid_ammo
        return "> ".bold.red + "The #{ammo.attribs['name']} is not valid ammunition."
      when :incompatible_ammo
        return "> ".bold.red + "#{ammo.attribs['name']} is not compatible ammo for the #{gun.attribs['name']}."
      when :insufficient_ammo
        return "> ".bold.red + "You don't have enough ammunition left."
      else
        return "> ".bold.red + "System error.  Report this to an administrator via +ticket."
      end        
    end
    
    ammo.rename
    R.nsoemit(enactor, "#{R.penn_name(enactor)} reloads #{R.penn_poss(enactor)} #{gun.attribs['name']}.")
    return "> ".bold.green + "You reload your #{gun.attribs['name']} with #{ammo.kind.group_name(result.last, ammo.attribs['name'])}."
  end
end