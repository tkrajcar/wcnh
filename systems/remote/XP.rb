require 'wcnh'

module XP
  PennJSON::register_object(self)

  def self.pj_view(target)
    self.view(target)
  end

  def self.pj_award(target,quantity,reason)
    self.award(target,quantity,reason)
  end

  def self.pj_add_nom(target,reason)
    self.add_nom(target,reason)
  end

  def self.pj_nom_view(target)
    self.nom_view(target)
  end

  def self.pj_run_noms
    self.run_noms
  end

  def self.pj_run_activity
    self.run_activity
  end
end
