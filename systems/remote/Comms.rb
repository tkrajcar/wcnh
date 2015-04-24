require 'wcnh'

module Comms
  PennJSON::register_object(self)

  def self.pj_handle_list(person)
    self.handle_list(person)
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

  def self.pj_handle_npc(handle)
    self.handle_npc(handle)
  end

  def self.pj_message_list_summary
    self.message_list_summary
  end

  def self.pj_message_list(handle,page=1)
    self.message_list(handle,page)
  end

  def self.pj_message_sent(page=1)
    self.message_sent(page)
  end

  def self.pj_message_send(handle,message)
    self.message_send(handle,message)
  end

  def self.pj_message_npc_send(from,to,message)
    self.message_npc_send(from,to,message)
  end

#  def self.pj_message_dnd(status = "toggle")
#    self.message_dnd(status)
#  end

  def self.pj_run_unread_message_notification
    self.run_unread_message_notification
  end

  def self.pj_message_unread
    self.message_unread
  end

  def self.pj_channel_list(person)
    self.channel_list(person)
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

  def self.pj_channel_emit(channel,handle,message)
    self.channel_emit(channel,handle,message)
  end
  
  def self.pj_channel_create(name,description,permission_type,permission_value)
    self.channel_create(name,description,permission_type,permission_value)
  end

  def self.pj_channel_tightbeam(channel,message)
    self.channel_tightbeam(channel,message)
  end

end
