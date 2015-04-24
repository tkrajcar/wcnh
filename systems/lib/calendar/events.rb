require 'wcnh'

module Calendar 

  def self.event_new(enactor)
    return "> ".bold.red + "Error creating event." unless event = Event.create!(:creator => enactor, :date => DateTime.new)
    R.set(enactor,"event:#{event.num}")
    Logs.log_syslog("CALENDAR", "#{R.penn_name(R["enactor"])} created a new event: #{event.num}.")
    return "> ".bold.green + "New event (no. #{event.num}) created.  See " + "help calendar events".bold.yellow + " for help." 
  end

  def self.event_edit(enactor, id)
    return "> ".bold.red + "Invalid calendar event." unless event = Event.where(:num => id).first
    if !(R.orflags(R["enactor"], "Wr").to_bool || R["enactor"] == event.creator) then
      return "> ".bold.red + "You can only edit your own events."
    end
    R.set(enactor,"event:#{event.num}")
    return "> ".bold.green + "Editing event no. #{event.num}.  See " + "help calendar events".bold.yellow + " for help."
  end

  def self.event_delete(id)
    return "> ".bold.red + "Invalid calendar event." unless event = Event.where(:num => id).first
    if !(R.orflags(R["enactor"], "Wr").to_bool || R["enactor"] == event.creator) then
      return "> ".bold.red + "You can only delete your own events."
    end
    Logs.log_syslog("CALENDAR","#{R.penn_name(R["enactor"])} has removed event no. #{event.num}.")
    event.destroy
    return "> ".bold.green + "Event no. #{event.num} removed."
  end

  def self.event_view(id)
    return "> ".bold.red + "No such calendar event number." unless event = Event.where(:num => id).first

    tz = R.penn_default(R["enactor"] + "/tz", "+0")

    ret = titlebar("Calendar Event ##{event.num}") + "\n"
    ret << "What: ".yellow + event.title.to_s + "\n"
    ret << "When: ".yellow + event.date.new_offset(tz).strftime("%B %d, %Y at %I:%M %p (%Z)") + "\n"
    ret << "Where: ".yellow + event.location.to_s + "\n"
    ret << "Who: ".yellow + "#{event.participants.count} Registrations "
    if R.orflags(R["enactor"],"Wr").to_bool then
      players = []
      event.participants.each { |j| players << R.penn_name(j) }
      ret << "(#{players.join(", ")})"
    end
    ret << "\n"
    ret << "Event Details: ".yellow + event.info.to_s + "\n"
    ret << footerbar
    ret
  end

  def self.event_change(id, field, criteria)
    return "> ".bold.red + "Invalid calendar event." unless event = Event.where(:num => id).first

    case field
    when "date"
      tz = R.penn_default(R["enactor"] + "/tz", "+0") 
      if !(date = self.date_to_datetime(event.date, criteria, tz)) then
        return "> ".bold.red + "Invalid date.  Date must be in the form of <day> <month> <year>. I.e., 01 Jan 2012."
      end
      event.date = date
      event.save
      return "> ".bold.green + "Event date updated."
    when "time"
      tz = R.penn_default(R["enactor"] + "/tz", "+0") 
      if !(time = self.time_to_datetime(event.date, criteria, tz)) then
        return "> ".bold.red + "Invalid time.  Time must be in the form of <hour>:<minute> AM/PM.  I.e., 3:30 PM."
      end
      event.date = time
      event.save
      return "> ".bold.green + "Event time updated."
    when "info"
      event.info = criteria
      event.save
      return "> ".bold.green + "Event details updated."
    when "location"
      event.location = criteria
      event.save
      return "> ".bold.green + "Event location updated."
    when "title"
      event.title = criteria
      event.save
      return "> ".bold.green + "Event title updated."
    end

    return "> ".bold.red + "Unrecognized argument."
  end

  def self.date_to_datetime(utc, string, tz)
    date = utc.new_offset(tz)
    date_format = (string.split[1].to_i > 0) ? "%d %m %Y %H:%M %z" : "%d %b %Y %H:%M %z"
    begin
      newdate = DateTime.strptime(string + " #{date.hour}:#{date.minute}" + tz, date_format)
    rescue
      return nil
    end 
    return newdate.new_offset(DateTime.now.zone)
  end

  def self.time_to_datetime(utc, string, tz)
    date = utc.new_offset(tz)
    time_format = (string.split.length > 1) ? "%d %m %Y %I:%M %p %z" : "%d %m %Y %H:%M %z"
    begin
      newdate = DateTime.strptime("#{date.day} #{date.month} #{date.year} " + string + tz, time_format)
    rescue
      return nil
    end
    return newdate.new_offset(DateTime.now.zone)
  end

end
