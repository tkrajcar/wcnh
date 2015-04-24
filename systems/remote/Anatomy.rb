require 'wcnh'

module Anatomy
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_scan(dbref)
    self.scan(dbref)
  end
  
  def self.pj_injure(dbref, part, damage)
    self.injure(dbref, part.length > 0 ? part : nil, damage)
  end
  
  def self.pj_cronHeal
    self.cronHeal
  end
  
  def self.pj_heal(healer, dbref, part, skill_medicine, skill_firstaid)
    self.heal(healer, dbref, part, skill_medicine, skill_firstaid)
  end
  
  def self.pj_heal_admin(target)
    self.heal_admin(target)
  end
  
  def self.pj_cronUncon
    self.cronUncon
  end
end
