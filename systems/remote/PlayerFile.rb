require 'wcnh'

module PlayerFile
  PennJSON::register_object(self)

  def self.pj_register(email,dbref)
    self.register(email,dbref)
  end

  def self.pj_register_secondary(email,dbref)
    self.register(email,dbref,false)
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
    self.view_connections(file)
  end

  def self.pj_search_connections(term)
    self.search_connections(term)
  end

  def self.pj_connect(pfile,ip,host,descriptor,dbref)
    self.connect(pfile,ip,host,descriptor,dbref)
  end

  def self.pj_disconnect(pfile,descriptor)
    self.disconnect(pfile,descriptor)
  end
end


