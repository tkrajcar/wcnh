require 'wcnh'

module Zones
  PennJSON::register_object(self)
  R = PennJSON::Remote

  def self.pj_checkout(bc, dbref)
    self.checkout(bc,dbref)
  end

  def self.pj_history(bc)
    self.history(bc)
  end

end
