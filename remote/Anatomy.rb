require 'wcnh'

module Anatomy
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_scan(dbref)
    self.scan(dbref)
  end
end
