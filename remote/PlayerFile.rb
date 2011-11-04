require 'wcnh'

module PlayerFile
  PennJSON::register_object(self)

  def self.pj_register(email,dbref)
    self.register(email,dbref)
  end

  def self.pj_view(file)
    self.view_file(file)
  end

  def self.pj_add_note(arg,note,category="Misc")
    self.add_note(arg,note,category)
  end

  def self.pj_search(term)
    self.search(term)
  end

  def self.pj_view_connections(file)
    "Not implemented."
  end

  def self.pj_search_connections(term)
    "Not implemented."
  end

  def self.pj_connect()
    "Not Implemented."
  end

  def self.pj_disconnect()
    "Not implemented."
  end
end


