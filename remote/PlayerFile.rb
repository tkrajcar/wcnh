require 'wcnh'

module PlayerFile
  PennJSON::register_object(self)

  def self.pj_register_email(dbref, email)
    self.register_email(dbref,email)
  end
  def self.pj_find_email(email)
    self.find_email(email)
  end
end


