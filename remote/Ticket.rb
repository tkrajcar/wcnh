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

  def self.pj_comment(ticket,comment,privacy = "private")
    "Not implemented"
  end

  def self.pj_close(ticket)
    "Not implemented"
  end

  def self.pj_reopen(ticket)
    "Not implemented"
  end

  def self.pj_assign(ticket,victim)
    self.assign(ticket,victim)
  end

  def self.view(ticket)
    "Not implemented"
  end
end