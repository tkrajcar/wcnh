require 'wcnh'

module BBoard
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_toc
    self.toc
  end
  
  def self.pj_index(cat)
    self.index(cat)
  end
  
  def self.pj_read(cat, num)
    self.read(cat, num)
  end
end
