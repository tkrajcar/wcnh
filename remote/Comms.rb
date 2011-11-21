require 'wcnh'

module Comms
  PennJSON::register_object(self)

  def self.pj_handle_list
    self.handle_list
  end

  def self.pj_handle_register(handle)
    self.handle_register(handle)
  end

  def self.pj_handle_unregister(handle)
    self.handle_unregister(handle)
  end

  def self.pj_handle_use(handle)
    self.handle_use(handle)
  end

  def self.pj_message_list_summary
    self.message_list_summary
  end

  def self.pj_message_list(handle,page=1)
    self.message_list(handle,page)
  end

  def self.pj_message_send(handle,message)
    self.message_send(handle,message)
  end

  def self.pj_message_dnd(status = "toggle")
    self.message_dnd(status)
  end

  def self.pj_message_unread
    self.message_unread
  end

  def self.pj_channel_list
    self.channel_list
  end

  def self.pj_channel_on(channel,shortcut)
    self.channel_on(channel,shortcut)
  end

  def self.pj_channel_off(channel)
    self.channel_off(channel)
  end

  def self.pj_channel_handle(channel,handle)
    self.channel_handle(channel,handle)
  end

  def self.pj_channel_transmit(channel,message)
    self.channel_transmit(channel,message)
  end
end