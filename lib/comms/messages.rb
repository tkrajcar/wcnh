require 'wcnh'

module Comms
  def self.message_unread
    c = Comlink.find_or_create_by(id: R["enactor"])
    return "> ".bold.yellow + "No unread messages." unless c.unread_tightbeams.length > 0

    msgs = c.unread_tightbeams
    ret = titlebar("All Unread Messages") + "\n"
    msgs.each do |msg_id|
      next unless msg = Tightbeam.find(msg_id)
      ret << "Received #{msg.ic_timestamp.strftime("%m/%d/%Y %H:%M").bold} from #{msg.from_handle.bold.white}: ".cyan #TODO - correct for IC
      ret << msg.body + "\n"
    end
    c.unread_tightbeams = []
    c.save
    ret << footerbar()
  end

  def self.message_list(handle,page=1)
    c = Comlink.find_or_create_by(id: R["enactor"])
    return "> ".bold.yellow + "Recipient handle not found." unless recipient = Comlink.where(lowercase_handles: handle.downcase).first
    proper_handle = recipient.handles[recipient.lowercase_handles.find_index(handle.downcase)] # properly-cased handle

    # from handle, to any of enactor's handles.
    # use any_in here since we need to match any one of c.handles, not the entire thing
    msgs = Tightbeam.any_in(to_handles: c.handles).where(from_handle: proper_handle)
    # from enactor, to handle.
    #msgs_to = Tightbeam.where(from: c.id, to_handles: [proper_handle])

    return "> ".bold.yellow + "No tightbeam messages between you and #{proper_handle.bold}." unless msgs.all.length > 0

    list_output(msgs, c, "Tightbeam From #{proper_handle}")
  end

  def self.message_list_summary
    c = Comlink.find_or_create_by(id: R["enactor"])
    msgs = Tightbeam.any_in(to_handles: c.handles)

    return "> ".bold.yellow + "No messages received at your registered handles!" unless msgs.all.length > 0

    list_output(msgs, c, "Recent Tightbeam Messages", 1, true)
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

  def self.list_output(criteria, comlink, title, page=1, showfrom = false)
    ret = titlebar("#{title} (Page #{page})") + "\n"
    msgs = criteria.desc(:ic_timestamp)
    if page.to_i > 0 # paginate
      msgs = msgs.skip(10 * (page.to_i - 1)).limit(10)
    end
    msgs.each do |msg|
      if comlink.unread_tightbeams.include?(msg.id)
        ret << "UNREAD> ".bold.red
        comlink.unread_tightbeams.delete(msg.id)
      end
      ret << "Received #{msg.ic_timestamp.strftime("%m/%d/%Y %H:%M").bold}#{showfrom ? " from " + msg.from_handle.bold.white : ""}: ".cyan #TODO - correct for IC
      ret << msg.body + "\n"
    end
    comlink.save # update unread_tightbeams field
    ret << footerbar()
  end
end
