require 'wcnh'

module Comms
  def self.message_list(handle,page=1)
    c = Comlink.find_or_create_by(id: R["enactor"])
    return "> ".bold.yellow + "Recipient handle not found." unless recipient = Comlink.where(lowercase_handles: handle.downcase).first
    proper_handle = recipient.handles[recipient.lowercase_handles.find_index(handle.downcase)] # properly-cased handle

    # from handle, to any of enactor's handles.
    # use any_in here since we need to match any one of c.handles, not the entire thing
    msgs = Tightbeam.any_in(to_handles: c.handles).where(from_handle: proper_handle)
    # from enactor, to handle.
    #msgs_to = Tightbeam.where(from: c.id, to_handles: [proper_handle])

    # sort & paginate
    msgs = msgs.desc(:ic_timestamp).skip(10 * (page.to_i - 1)).limit(10)

    return "> ".bold.yellow + "No tightbeam messages between you and #{proper_handle.bold}." unless msgs.all.length > 0
    ret = titlebar("Tightbeam Messages Between You And #{proper_handle} (Page #{page})") + "\n"
    msgs.each do |msg|
      ret << "Received #{msg.ic_timestamp.strftime("%m/%d/%Y %H:%m").bold}\n".cyan #TODO - correct for IC
      ret << msg.body + "\n"
    end
    ret << footerbar()
    ret
  end

  def self.message_send(handle, message)
    sender = Comlink.find_or_create_by(id: R["enactor"])
    return "> ".bold.yellow + "Recipient handle not found." unless recipient = Comlink.where(lowercase_handles: handle.downcase).first

    proper_handle = recipient.handles[recipient.lowercase_handles.find_index(handle.downcase)] # properly-cased handle

    tb = Tightbeam.new
    tb.from = sender.id
    tb.from_handle = sender.active_handle
    tb.to_handles = [proper_handle]
    tb.body = message
    tb.save

    recipient.unread_tightbeams << tb.id
    recipient.save

    R.nspemit(recipient.id, "> ".bold.yellow + "New tightbeam message received from #{sender.active_handle.bold}.") unless recipient.dnd_on
    return "> ".bold.yellow + "Tightbeam message sent to #{proper_handle.bold}."
  end

  def self.message_dnd(status="toggle")
    c = Comlink.find_or_create_by(id: R["enactor"])
    if status == "on"
      c.dnd_on = true
    elsif status == "off"
      c.dnd_on = false
    else
      c.dnd_on = !c.dnd_on
    end
    c.save
    "> ".bold.yellow + "Do-not-disturb set to #{c.dnd_on ? "on".bold : "off".bold}."
  end
end
