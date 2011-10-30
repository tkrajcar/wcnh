require 'pennmush-json'

module Sysinf
  PennJSON::register_object(self)
  
  def self.pj_loadpath(*args)
    return $LOAD_PATH.to_s
  end
end
