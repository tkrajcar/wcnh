require 'wcnh'

module Calendar

  def self.event_new(enactor)
    return "> ".bold.red + "Error creating event." unless event = Event.create!(:creator => enactor, :date => DateTime.new.utc)
    R.set("#5","event:#{event.num}")
    return "> ".bold.green + "New event (no. #{event.num}) created.  See " + "help calendar events".bold.yellow + " for help."
  end

  def self.event_view(id)
    return "> ".bold.red + "No such calendar event number." unless event = Event.where(:num => id).first

    tz = R.xget(R["enactor"], "tz").to_i

    ret = titlebar("Calendar Event ##{event.num}") + "\n"
    ret << "What: ".yellow + event.title.to_s + "\n"
    ret << "When: ".yellow + event.date.new_offset(Rational(tz, 24)).strftime("%B %d, %Y at %I:%M %p %Z") + "\n"
    ret << "Where: ".yellow + event.location.to_s + "\n"
    ret << "Event Details: ".yellow + event.info.to_s + "\n"
    ret << footerbar
    ret
  end

  def self.event_change(id, field, criteria)
    return "> ".bold.red + "Invalid calendar event." unless event = Event.where(:num => id).first

    case field
    when "date"
      if !(date = self.date_to_datetime(criteria)) then
        return "> ".bold.red + "Invalid date.  Date must be in the form of <day> <month> <year>. I.e., 01 Jan 2012."
      end
      date = date.new_offset
      event.date = event.date.change(:day => date.day, :month => date.month, :year => date.year)
      event.save
      return "> ".bold.green + "Event date updated."
    when "time"
      if !(time = self.time_to_datetime(criteria)) then
        return "> ".bold.red + "Invalid time.  Time must be in the form of <hour>:<minute> AM/PM.  I.e., 3:30 PM."
      end
      event.date = event.date.change(:hour => time.hour, :min => time.minute)
      event.save
      return "> ".bold.green + "Event time updated."

    end

    return "> ".bold.red + "Unrecognized argument."
  end

  def self.date_to_datetime(string)
    date_format = (string.split[1].to_i > 0) ? "%d %m %Y" : "%d %b %Y"
    begin
      date = DateTime.strptime(string, date_format)
    rescue
      return nil
    end
    return date
  end

  def self.time_to_datetime(string)
    time_format = (string.split.length > 1) ? "%I:%M %p" : "%H:%M"
    begin
      time = DateTime.strptime(string, time_format)
    rescue
      return nil
    end
    return time
  end

end
