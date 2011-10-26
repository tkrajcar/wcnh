require 'pennmush-json'

module Pong
  PennJSON::register_object(self)
  
  REMOET = PennJSON::Remote

  def self.pj_pong(*args)
    return "PONG. #{args.inspect}"
  end
end
