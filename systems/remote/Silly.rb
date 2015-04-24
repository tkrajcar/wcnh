require 'wcnh'

module Silly
  PennJSON::register_object(self)

  def self.pj_fnord
    return Fnord.sentence
  end
end
