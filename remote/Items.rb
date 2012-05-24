require 'wcnh'

module Items
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_get_attr(dbref, attr)
    self.get_attr(dbref, attr)
  end
end