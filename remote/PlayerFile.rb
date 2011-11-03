require 'wcnh'

module PlayerFile
  PennJSON::register_object(self)

  def self.pj_register(email,dbref)
    self.register(email,dbref)
  end

  def self.pj_view(file)
    self.view_file(file)
  end



  def self.pj_ip(file)

  end

  def self.pj_search(term)

  end

  def self.pj_add(file,category,note)

  end

  def self.pj_connect()

  end

  def self.pj_disconnect()

  end
end


