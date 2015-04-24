require 'wcnh'

module Shiprace

  PennJSON::register_object(self)
  R = PennJSON::Remote

  def self.pj_purchase(dbref, skill, wager, position)
    self.purchase(dbref, skill.to_i, wager.to_i, position.to_i)
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
  
  def self.pj_history
    self.history
  end
  
  def self.pj_record(racer)
    self.record(racer)
  end

end
