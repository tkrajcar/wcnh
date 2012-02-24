require 'wcnh'

module Shiprace

  PennJSON::register_object(self)
  R = PennJSON::Remote

  def self.pj_purchase(dbref, skill)
    self.purchase(dbref, skill.to_i)
  end

  def self.pj_buildroster
    self.buildroster
  end

  def self.pj_roster
    self.roster
  end

  def self.pj_runrace
    self.runrace
  end

  def self.pj_tickets
    self.tickets
  end

end
