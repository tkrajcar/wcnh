require 'wcnh'

module Calendar
  PennJSON::register_object(self)
  R = PennJSON::Remote

  def self.pj_event_view(id)
    self.event_view(id)
  end

  def self.pj_search(criteria)
    self.search(criteria)
  end

  def self.pj_event_new(enactor)
    self.event_new(enactor)
  end

  def self.pj_event_edit(enactor, id)
    self.event_edit(enactor, id)
  end

  def self.pj_event_change(id, field, value)
    self.event_change(id, field, value)
  end

end
