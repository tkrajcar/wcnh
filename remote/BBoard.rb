require 'wcnh'

module BBoard
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_list(dbref)
    self.list(dbref)
  end
  
  def self.pj_toc
    self.toc
  end
  
  def self.pj_index(cat)
    self.index(cat)
  end
  
  def self.pj_read(cat, num)
    self.read(cat, num)
  end
  
  def self.pj_post(author, cat, sub, txt)
    self.post(author, cat, sub, txt)
  end
  
  def self.pj_draft_start(dbref, cat, sub)
    self.draft_start(dbref, cat, sub)
  end
  
  def self.pj_draft_write(dbref, txt)
    self.draft_write(dbref, txt)
  end
  
  def self.pj_draft_proof(dbref)
    self.draft_proof(dbref)
  end
  
  def self.pj_draft_toss(dbref)
    self.draft_toss(dbref)
  end
  
  def self.draft_post(dbref)
    self.draft_post(dbref)
  end
  
  def self.pj_category_create(cat)
    self.category_create(cat)
  end
  
  def self.category_config(cat, opt, val)
    self.category_config(cat, opt, val)
  end
end