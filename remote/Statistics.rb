require 'wcnh'

module Statistics
  PennJSON::register_object(self)

  def self.pj_log(lwho)
    self.log(lwho)
  end
end
