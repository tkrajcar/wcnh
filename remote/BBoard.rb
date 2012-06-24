require 'wcnh'

module BBoard
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_test(dbref)
    self.test(dbref)
  end
  
  def self.pj_list(dbref)
    self.list(dbref)
  end
  
  def self.pj_toc(dbref)
    self.toc(dbref)
  end
  
  def self.pj_index(dbref, cat)
    self.index(dbref, cat)
  end
  
  def self.pj_read(dbref, cat, num)
    self.read(dbref, cat, num)
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
  
  def self.pj_draft_post(dbref)
    self.draft_post(dbref)
  end
  
  def self.pj_category_create(cat)
    self.category_create(cat)
  end
  
  def self.pj_category_config(cat, opt, val)
    self.category_config(cat, opt, val)
  end
  
  def self.pj_join(dbref, cat)
    self.join(dbref, cat)
  end
  
  def self.pj_leave(dbref, cat)
    self.leave(dbref, cat)
  end
  
  def self.pj_replies(dbref, cat, num)
    self.read(dbref, cat, num, true)
  end
  
  def self.pj_catchup(dbref, cat)
    self.catchup(dbref, cat)
  end
  
  def self.pj_next(dbref)
    self.next(dbref)
  end
  
  def self.pj_remove(dbref, cat, num)
    self.remove(dbref, cat, num)
  end
  
  def self.pj_sticky(dbref, cat, num, status)
    self.sticky(dbref, cat, num, (status.to_i > 0 ? true : false))
  end
  
  def self.pj_edit(dbref, cat, num, txt, rep)
    self.edit(dbref, cat, num, txt, rep)
  end
  
  def self.pj_scan(dbref)
    self.scan(dbref)
  end

  def self.pj_search(dbref, cat, term)
    self.search(dbref, cat, term)
  end

  def self.pj_timeout
    self.timeout
  end
end