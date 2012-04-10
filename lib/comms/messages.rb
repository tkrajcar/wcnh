require 'wcnh'

module Comms
  def self.run_unread_message_notification
    R.lwho().split(" ").each do |player|
      next unless Comlink.exists?(conditions: {id: player})
      c = Comlink.find(player)
      if c.unread_tightbeams.length > 0
        R.nspemit(player,"> ".bold.yellow + "You have " + c.unread_tightbeams.length.to_s.bold + " unread tightbeam message#{c.unread_tightbeams.length > 1 ? "s" : ""}.")
      end
    end
    ""
  end

  def self.message_unread
    c = Comlink.find_or_create_by(id: R["enactor"])
    return "> ".bold.yellow + "No unread messages." unless c.unread_tightbeams.length > 0

    msgs = c.unread_tightbeams
    ret = titlebar("All Unread Messages") + "\n"
    msgs.each do |msg_id|
      next unless msg = Tightbeam.find(msg_id)
      tz = GAME_TIME
      tz = R.xget(R["enactor"],"TZ").to_i if R.hasattr(R["enactor"],"TZ").to_bool
      ret << "Received #{msg.ic_timestamp.in_time_zone(tz).strftime("%m/%d/%Y %H:%M").bold} from #{msg.from_handle.bold.white}: ".cyan #TODO - correct for IC
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

  def self.message_sent(page=1)
    c = Comlink.find_or_create_by(id: R["enactor"])
    msgs = Tightbeam.where(from: R["enactor"])

    return "> ".bold.yellow + "No tightbeam messages sent." unless msgs.length > 0

    list_output(msgs, c, "Tightbeam Messages Sent", page, true)
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

    R.nspemit(recipient.id, "> ".bold.yellow + "New tightbeam message received from #{sender.active_handle.bold}.")
    R.u("#65/fn.npc_message_recvd",tb.from,tb.from_handle,proper_handle,message) if recipient._id == "#1"
    return "> ".bold.yellow + "Tightbeam message sent to #{proper_handle.bold}."
  end

  def self.message_npc_send(from, handle, message)
    return "> ".bold.yellow + "That handle is not registered as a NPC handle." unless Comlink.find("#1").handles.include?(from)
    return "> ".bold.yellow + "Recipient handle not found." unless recipient = Comlink.where(lowercase_handles: handle.downcase).first

    proper_handle = recipient.handles[recipient.lowercase_handles.find_index(handle.downcase)] # properly-cased handle

    tb = Tightbeam.new
    tb.from = "#1"
    tb.from_handle = from
    tb.to_handles = [proper_handle]
    tb.body = message
    tb.save

    recipient.unread_tightbeams << tb.id
    recipient.save

    R.nspemit(recipient.id, "> ".bold.yellow + "New tightbeam message received from #{from.bold}.")
    R.u("#65/fn.npc_message_sent",R["enactor"],from,proper_handle,message)
    return "> ".bold.yellow + "Tightbeam message sent from #{from.bold.cyan} to #{proper_handle.bold}."
  end

#  def self.message_dnd(status="toggle")
#    c = Comlink.find_or_create_by(id: R["enactor"])
#    if status == "on"
#      c.dnd_on = true
#    elsif status == "off"
#      c.dnd_on = false
#    else
#      c.dnd_on = !c.dnd_on
#    end
#    c.save
#    "> ".bold.yellow + "Do-not-disturb set to #{c.dnd_on ? "on".bold : "off".bold}."
#  end

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
      to_handles_list = msg.to_handles.collect {|i| i.bold}.to_sentence

      tz = GAME_TIME
      tz = R.xget(R["enactor"],"TZ").to_i if R.hasattr(R["enactor"],"TZ").to_bool
      ret << "#{msg.ic_timestamp.in_time_zone(tz).strftime("%m/%d/%Y %H:%M").bold}#{showfrom ? " from " + msg.from_handle.bold.white : ""} to #{to_handles_list}: ".cyan

      ret << msg.body + "\n"
    end
    comlink.save # update unread_tightbeams field
    ret << footerbar()
  end
end
