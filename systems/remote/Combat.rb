module Combat
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_reload(enactor, gun, ammo)
    self.reload(enactor, gun, ammo)
  end
end