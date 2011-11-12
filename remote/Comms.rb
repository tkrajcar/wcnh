require 'wcnh'

module Comms
  PennJSON::register_object(self)

  def self.pj_handle_list
    "Not implemented."
  end

  def self.pj_handle_register(handle)
    "Not implemented."
  end

  def self.pj_handle_unregister(handle)
    "Not implemented."
  end

  def self.pj_handle_use(handle)
    "Not implemented."
  end

  def self.pj_message_list_summary
    "Not implemented."
  end

  def self.pj_message_list(handle,page=1)
    "Not implemented."
  end

  def self.pj_message_send(handle,message)
    "Not implemented."
  end

  def self.pj_message_dnd(status)
    "Not implemented."
  end

  def self.pj_message_unread
    "Not implemented."
  end

  def self.pj_channel_list
    "Not implemented."
  end

  def self.pj_channel_on(channel,shortcut)
    "Not implemented."
  end

  def self.pj_channel_off(channel)
    "Not implemented."
  end

  def self.pj_channel_handle(channel,handle)
    "Not implemented."
  end

  def self.pj_channel_transmit(channel,message)
    "Not implemented."
  end
end