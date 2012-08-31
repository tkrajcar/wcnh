require 'wcnh'

module Ticket
  PennJSON::register_object(self)

  def self.pj_open(title,data)
    self.open(title,data)
  end

  def self.pj_list(page)
    self.list(page)
  end

  def self.pj_list_mine(page)
    self.mine(page)
  end

  def self.pj_comment(ticket,comment,privacy = true)
    self.comment(ticket,comment,privacy.to_bool)
  end

  def self.pj_close(ticket)
    self.close(ticket)
  end

  def self.pj_reopen(ticket)
    self.reopen(ticket)
  end

  def self.pj_assign(ticket,victim)
    self.assign(ticket,victim)
  end

  def self.pj_view(ticket)
    self.view(ticket)
  end
  
  def self.pj_rename(ticket, name)
    self.rename(ticket, name)
  end
  
  def self.pj_sort(sort_type)
    self.sort(sort_type)
  end
end