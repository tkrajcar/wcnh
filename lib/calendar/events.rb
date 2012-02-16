require 'wcnh'

module Calendar

  def self.list(month, year)
    tz = R.xget(R["enactor"], "tz")
    start = (month.length > 0 && year.length > 0) ? self.date_to_datetime("01 #{month} #{year}", "+0") : DateTime.now
    range = start..start + 30.days

    return "> ".bold.red + "No events found." unless events = Event.where(date: range)
    ret = titlebar("Calendar Events from #{start.strftime("%b %d %Y")} to #{range.last.strftime("%b %d %Y")}") + "\n"
    ret << " Num".ljust(5).yellow + "Title".ljust(25).yellow + "Creator".ljust(25).yellow + "Time (TZ = #{tz})".yellow + "\n"
    events.all.each do |event|
      ret << " #{event.num}".ljust(5) + event.title.to_s.ljust(25) + R.penn_name(event.creator.to_s).ljust(25) + event.date.new_offset(Rational(tz, 24)).strftime("%d %b %Y @ %H:%M")
      ret << "\n"
    end
    ret << footerbar
    ret
  end
    

  def self.event_new(enactor)
    return "> ".bold.red + "Error creating event." unless event = Event.create!(:creator => enactor, :date => DateTime.new.utc)
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
    return "> ".bold.green + "Editing event no. #{event.num}).  See " + "help calendar events".bold.yellow + " for help."
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

    tz = R.xget(R["enactor"], "tz").to_i

    ret = titlebar("Calendar Event ##{event.num}") + "\n"
    ret << "What: ".yellow + event.title.to_s + "\n"
    ret << "When: ".yellow + event.date.new_offset(Rational(tz, 24)).strftime("%B %d, %Y at %I:%M %p (%Z)") + "\n"
    ret << "Where: ".yellow + event.location.to_s + "\n"
    ret << "Event Details: ".yellow + event.info.to_s + "\n"
    ret << footerbar
    ret
  end

  def self.event_change(id, field, criteria)
    return "> ".bold.red + "Invalid calendar event." unless event = Event.where(:num => id).first

    case field
    when "date"
      tz = R.xget(R["enactor"], "tz").to_i
      if !(date = self.date_to_datetime(criteria, tz)) then
        return "> ".bold.red + "Invalid date.  Date must be in the form of <day> <month> <year>. I.e., 01 Jan 2012."
      end
      event.date = event.date.change(:day => date.day, :month => date.month, :year => date.year)
      event.save
      return "> ".bold.green + "Event date updated."
    when "time"
      tz = R.xget(R["enactor"], "tz").to_i
      if !(time = self.time_to_datetime(criteria, tz)) then
        return "> ".bold.red + "Invalid time.  Time must be in the form of <hour>:<minute> AM/PM.  I.e., 3:30 PM."
      end
      event.date = event.date.change(:hour => time.hour, :min => time.minute)
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

  def self.date_to_datetime(string, tz)
    date_format = (string.split[1].to_i > 0) ? "%d %m %Y %z" : "%d %b %Y %z"
    begin
      date = DateTime.strptime(string + " " + tz.to_s, date_format)
    rescue
      return nil
    end
    return date
  end

  def self.time_to_datetime(string, tz)
    time_format = (string.split.length > 1) ? "%I:%M %p %z" : "%H:%M %z"
    begin
      time = DateTime.strptime(string + " " + tz.to_s, time_format)
    rescue
      return nil
    end
    return time
  end

end
