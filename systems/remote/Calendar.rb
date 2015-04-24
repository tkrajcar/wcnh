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

  def self.pj_list(user, month, year)
    self.list(user, month, year)
  end

  def self.pj_event_delete(id)
    self.event_delete(id)
  end
  
  def self.pj_notify
    self.notify
  end
  
  def self.pj_register(num,dbref)
    self.register(num,dbref)
  end
  
  def self.pj_unregister(num,dbref)
    self.unregister(num,dbref)
  end

end
