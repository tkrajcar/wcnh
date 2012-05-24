require 'wcnh'

module Items
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_get_attr(dbref, attr)
    self.get_attr(dbref, attr)
  end
  
  def self.pj_list(kind=nil)
    self.list(kind)
  end
end