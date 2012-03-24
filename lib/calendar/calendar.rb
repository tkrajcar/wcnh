require 'wcnh'

module Calendar

  def self.list(month, year)
    tz = R.penn_default(R["enactor"] + "/tz", "+0") 
    start = (month.length > 0 && year.length > 0) ? self.date_to_datetime(DateTime.now.midnight, "01 #{month} #{year}", "+0") : DateTime.now
    range = start..start + 30.days
    events = Event.where(date: range)

    return "> ".bold.red + "No events found." unless (events.count > 0)
    ret = titlebar("Calendar Events from #{start.strftime("%b %d %Y")} to #{range.last.strftime("%b %d %Y")}") + "\n"
    ret << " Num".ljust(5).yellow + "Title".ljust(25).yellow + "Creator".ljust(25).yellow + "Time (TZ = #{tz})".yellow + "\n"
    events.all.each do |event|
      ret << " #{event.num}".ljust(5) + event.title.to_s.ljust(25) + R.penn_name(event.creator.to_s).ljust(25) + event.date.new_offset(tz).strftime("%d %b %Y @ %H:%M")
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

end  
