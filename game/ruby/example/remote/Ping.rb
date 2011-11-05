require 'pennmush-json'
require 'pennmush-json-example'

module Ping
  PennJSON::register_object(self)

  REMOTE = PennJSON::Remote

  def self.pj_ping(arg)
    # Remote call example using context.
    result = REMOTE.pemit(REMOTE['enactor'], arg)

    # This ensures context was properly restored after remote call.
    return "#{result}->#{REMOTE['enactor']}"
  end

  def self.pj_div0
    # StandardError subclass and support module example.
    return PennMUSH_Example.div(1, 0)
  end

  def self.pj_pong(*args)
    return "PONG#{args.inspect}"
  end

  def self.pj_eval(arg)
    return REMOTE.s(arg)
  end

  def self.pj_invoke(name, *args)
    return REMOTE.method_missing(name, *args)
  end

  def self.pj_exit
    # SystemExit example; not enabled by default, for obvious reasons.
    #exit
  end

  def self.pj_callback
    # Callback example.
    PennJSON::invoke_later do
      next REMOTE.lwho
    end
  end
end
