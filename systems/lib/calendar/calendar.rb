require 'wcnh'

module Calendar

  def self.list(user, month, year)
    tz = R.penn_default(user + "/tz", "+0") 
    start = (month.length > 0 && year.length > 0) ? self.date_to_datetime(DateTime.now.midnight, "01 #{month} #{year}", "+0") : DateTime.now
    range = start..start + 30.days
    events = Event.where(date: range).desc(:date)

    return "> ".bold.red + "No events found." unless (events.count > 0)
    ret = titlebar("Calendar Events from #{start.strftime("%b %d %Y")} to #{range.last.strftime("%b %d %Y")}") + "\n"
    ret << " Num".ljust(5).yellow + "Title".ljust(29).yellow + "Creator".ljust(25).yellow + "Time (TZ = #{tz})".yellow + "\n"
    events.all.each do |event|
      ret << " #{event.num}".ljust(5) + event.title.to_s[0,29].ljust(29) + R.penn_name(event.creator.to_s).ljust(25) + event.date.new_offset(tz).strftime("%d %b %Y @ %H:%M")
      ret << "\n"
    end
    ret << footerbar
    ret
  end
  
  def self.notify
    range = DateTime.now..DateTime.now + 30.minutes
    events = Event.where(date: range)
    events.each do |i|
      R.nscemit("Public", "[#{"CALENDAR".cyan}] Event no. #{i.num}, '#{i.title}', begins in #{((i.date.to_time - Time.now) / 60).to_i} minutes.", "0")
    end
    return
  end
  
  def self.register(num,dbref)
    return "> ".bold.red + "No such calendar event number." unless event = Event.where(:num => num.to_i).first
    return "> ".bold.red + "You are already registered for that event." unless event.participants.find_index(dbref).nil?
    
    event.participants << dbref
    event.save
    R.mailsend(event.creator,"Event ##{event.num} Registration/#{R.penn_name(dbref)} has registered for +cal #{event.num}.")
    
    return "> ".bold.green + "You are now registered for event no. #{event.num}."
  end
  
  def self.unregister(num,dbref)
    return "> ".bold.red + "No such calendar event number." unless event = Event.where(:num => num).first
    return "> ".bold.red + "You are not registered for that event." unless index = event.participants.find_index(dbref)
    
    event.participants.delete_at(index)
    event.save
    R.mailsend(event.creator,"Event ##{event.num} Unregister/#{R.penn_name(dbref)} has cancelled their registration for +cal #{event.num}.")
    
    return "> ".bold.green + "You have cancelled your registration for event no. #{event.num}."
  end

end  
