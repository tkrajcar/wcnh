require 'wcnh'

module Web
  PennJSON::register_object(self)

  def self.pj_register(password)
    self.register(password)
  end
end
