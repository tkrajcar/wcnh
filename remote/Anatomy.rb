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
  
  def self.pj_heal(dbref)
    self.heal(dbref)
  end
  
  def self.pj_cronHeal
    self.cronHeal
  end
end
