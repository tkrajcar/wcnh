#
# System remote module for dispatching "rpc." calls.
#

require 'pennmush-json'
require 'pennmush-json-conversation'

module PennJSON_System
  PennJSON::register_object(self, 'rpc')

  def self.pj_ack
    # This method may only be used at the top level.
    if PennJSON_Conversation::stack_depth != 1
      raise PennJSON::LocalError.new(-32603, 'Invalid usage of rpc.ack')
    end

    # Execute next callback. Only dequeue one at a time to avoid starvation.
    cb = PennJSON::CALLBACK_QUEUE.dequeue
    raise PennJSON::LocalError.new(-32603, 'Unsolicited rpc.ack') unless cb

    begin
      result = cb.call
    ensure
      PennJSON_Conversation::ack_solicit
    end

    return result
  end
end
