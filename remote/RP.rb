require 'wcnh'

module RP
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_toc
    self.toc
  end
  
  def self.pj_create(category, title, info)
    self.create(category, title, info)
  end
  
  def self.pj_view(id)
    self.view(id)
  end
  
  def self.pj_index(category, page=1)
    self.index(category, page)
  end
  
  def self.pj_search(term)
    self.search(term)
  end
  
  def self.pj_top
    self.top
  end
  
  def self.pj_recent(hours)
    self.recent(hours)
  end
  
  def self.pj_remove(num)
    self.remove(num)
  end
end
