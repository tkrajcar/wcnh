require 'wcnh'

module Comms
  MAX_NUMERIC_CHANNELS = 5
  REGEX_NUMERIC_CHANNEL = /\d\d\d\.\d\d/

  def self.channel_list
    c = Comlink.find_or_create_by(id: R["enactor"])
    ret = titlebar("Channel List") + "\n"
    ret << "#{'Alias'.ljust(7)} #{'Handle'.ljust(20)} #{'Name'.ljust(15)} Description\n".cyan
    Channel.all.find_all { |chan| chan.can_see?(R["enactor"])}.each do |channel|
      if mbr = c.memberships.where(channel: channel.lowercase_name).first
        ret << mbr.shortcut.ljust(8).green.bold
        ret << mbr.active_handle.ljust(21).cyan.bold
      else
        ret << "Off".ljust(29).red.bold
      end
      ret << channel.id.ljust(16).bold # channel name
      ret << channel.description[0...34]
      ret << "\n"
    end
    numeric = c.memberships.where(channel: REGEX_NUMERIC_CHANNEL) # match only ###.## format
    if numeric.length > 0
      numeric.each do |mbr|
        ret << mbr.shortcut.ljust(8).green.bold
        ret << mbr.active_handle.ljust(21).cyan.bold
        ret << mbr.channel.ljust(16).bold # channel name
        ret << "N/A (numeric channel)\n"
      end
    end
    ret << "\nYou are using #{numeric.length.to_s.bold.yellow} of your #{MAX_NUMERIC_CHANNELS.to_s.bold} allowed numeric channels.\n"

    ret << footerbar
  end

  def self.channel_on(channel,shortcut)
    c = Comlink.find_or_create_by(id: R["enactor"])
    channel.downcase!
    shortcut.downcase!

    return "> ".bold.yellow + "Shortcut too long - use 7 characters or less." unless shortcut.length < 8
    if c.memberships.where(channel: channel).all.length > 0
      return "> ".bold.yellow + "You're already on that channel!"
    end

    if channel =~ REGEX_NUMERIC_CHANNEL # match only ###.## format
      # Numeric channel.
      if c.memberships.where(channel: REGEX_NUMERIC_CHANNEL).length >= MAX_NUMERIC_CHANNELS
        return "> ".bold.yellow + "You can only be on #{MAX_NUMERIC_CHANNELS.to_s.bold} numeric channels at one time."
      end
      newmbr = c.memberships.create!(channel: channel, shortcut: shortcut, active_handle: c.active_handle)
      newchan = channel
    else
      # Named channel.
      return "> ".bold.yellow + "Channel not found." unless ch = Channel.where(lowercase_name: channel).first
      return "> ".bold.yellow + "You can't quite seem to figure out the encryption algorithms for that channel." unless ch.can_see?(R["enactor"])

      c.memberships.create!(channel: channel, shortcut: shortcut, active_handle: c.active_handle)
      newchan = ch.id
    end
    "> ".bold.yellow + "You have joined comm channel #{newchan.bold}, using handle #{c.active_handle.bold.cyan} and shortcut #{shortcut.bold.cyan}."
  end

  def self.channel_off(channel)
    c = Comlink.find_or_create_by(id: R["enactor"])
    channel.downcase!
    return "> ".bold.yellow + "You're not on that channel!" unless mbr = c.memberships.any_of({channel: channel}, {shortcut: channel}).first # find by channel or shortcut name
    mbr.delete
    c.save
    "> ".bold.yellow + "Left channel #{mbr.channel.bold}."
  end

  def self.channel_handle(channel,handle)
    c = Comlink.find_or_create_by(id: R["enactor"])
    channel.downcase!
    return "> ".bold.yellow + "That handle isn't registered, or isn't registered to you." unless c.lowercase_handles.include?(handle.downcase)
    return "> ".bold.yellow + "You're not on that channel!" unless mbr = c.memberships.any_of({channel: channel}, {shortcut: channel}).first # find by channel or shortcut name

    if mbr.channel =~ REGEX_NUMERIC_CHANNEL
      newch = mbr.channel
    else
      newch = Channel.where(lowercase_name: mbr.channel.downcase).first._id
    end

    proper_handle = c.handles[c.lowercase_handles.find_index(handle.downcase)] # properly-cased handle

    mbr.active_handle = proper_handle
    mbr.save
    "> ".bold.yellow + "Changed handle for #{newch.bold} to #{proper_handle.bold.yellow}."
  end

  def self.channel_transmit(channel,message)
    c = Comlink.find_or_create_by(id: R["enactor"])
    channel.downcase!
    return "> ".bold.yellow + "No channel or shortcut named #{channel.bold} found!" unless mymbr = c.memberships.any_of({channel: channel}, {shortcut: channel}).first # find by channel or shortcut name

    if mymbr.channel =~ REGEX_NUMERIC_CHANNEL
      ch = mymbr.channel
    else
      ch = Channel.where(lowercase_name: mymbr.channel).first._id
    end
    Comlink.where("memberships.channel" => ch.downcase).each do |comm|
      #mbr = comm.memberships.where(channel: channel).first
      R.nspemit(comm.id,"<".yellow.bold + ch.bold + ">".yellow.bold + " " + mymbr.active_handle.bold + ": ".yellow + message)
    end
    Transmission.create!(channel: ch, from: R["enactor"], from_handle: mymbr.active_handle, text: message)
    ""
  end

  def self.channel_create(name,description,permission_type,permission_value)
    ch = Channel.create!(id: name, description: description, permission_type: permission_type, permission_value: permission_value)
    ""
  end
end
