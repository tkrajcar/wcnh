require 'wcnh'

module Dossier
  PennJSON::register_object(self)

  def self.pj_view(object,page=1)
    self.view(object,page)
  end

  def self.pj_add(object,content)
    self.add(object,content)
  end

  def self.pj_wanted_list
    self.wanted_list
  end

  def self.pj_wanted_view(object)
    self.wanted_view(object)
  end

  def self.pj_wanted_set(object,field,value)
    self.wanted_set(object,field,value)
  end

  def self.pj_wanted_delete(object)
    self.wanted_delete(object)
  end
end
