require 'wcnh'

module Ticket
  R = PennJSON::Remote
  SORTS = [:title, :requester, :opened, :updated]
  
  def self.sort(sort_type)
    unless SORTS.include?(sort_type.to_sym)
      return "> ".bold.cyan + "Invalid sort type.  Valid sorts: " + SORTS.map { |i| i.upcase.to_s }.itemize
    end
    
    R.penn_set(R['enactor'], "ticket.sort:#{sort_type}")
    return "> ".bold.cyan + "Your ticket lists will now be sorted by: " + sort_type    
  end
  
  def self.rename(ticket, name)
    t = Ticket.where(number: ticket).first
    isadmin = R.orflags(R["enactor"],"Wr").to_bool
    return ">".bold.cyan + " Invalid ticket!" unless (!t.nil? && isadmin)
    t.title = name
    t.save
    return "> ".bold.cyan + "Ticket no. #{t.number} has been renamed."
  end
  
  # Open a new ticket
  def self.open(title, data)
    return ">".bold.cyan + " Sorry, guests can't open new tickets." unless !R.haspower(R["enactor"], "guest").to_bool
    t = Ticket.create!(title: title, body: data, requester: R["enactor"])
    team_notify("#{R.penn_name(R["enactor"]).bold} has opened a new ticket ##{t.number.to_s.bold.yellow}: #{title.bold.white}.")
    return ">".bold.cyan + " Ticket ##{t.number.to_s.bold} opened. We'll respond as soon as possible."
  end

  def self.list(page = 1)
    page = page.to_i
    sort_type = R.penn_xget(R['enactor'], 'ticket.sort').to_s.to_sym
    sort_type = SORTS.include?(sort_type) ? sort_type : :opened 
    return ">".bold.cyan + " Invalid page number." unless page > 0
    if R.orflags(R["enactor"],"Wr").to_bool
      list_output(Ticket.all, "All +Tickets",page,true,sort_type)
    else
      list_output(Ticket.where(requester: R["enactor"]), "Your Opened +Tickets",page,false,sort_type)
    end
  end

  def self.mine(page)
    page = page.to_i
    sort_type = R.penn_xget(R['enactor'], 'ticket.sort').to_s.to_sym
    sort_type = SORTS.include?(sort_type) ? sort_type : :opened
    return ">".bold.cyan + " Invalid page number." unless page > 0
    tickets = Ticket.where(assignee: R["enactor"]).where(status: "open")
    return ">".bold.cyan + " No open +tickets assigned to you." unless tickets.length > 0
    list_output(tickets, "Your Assigned +Tickets", page, true, sort_type)
  end

  def self.assign(ticket,victim)
    return ">".bold.cyan + " Invalid ticket!" unless t = Ticket.where(number: ticket).first
    p = R.pmatch(victim)
    return ">".bold.cyan + " Invalid assignee!" unless R.orflags(p,"Wr").to_bool || victim == "none"
    t.assignee = (victim == "none" ? nil : p)
    t.updated = DateTime.now
    t.comments.create!(author: R["enactor"], text: "+ticket assigned to #{victim == "none" ? "nobody" : R.penn_name(p)}.", private: true)
    t.save
    team_notify("#{R.penn_name(R["enactor"]).bold} has assigned ticket ##{t.number.to_s.bold.white} to #{victim == "none" ? "nobody".bold.yellow : R.penn_name(p).bold.yellow}.")
    ">".bold.cyan + " Ticket #{t.number.to_s.bold} assigned to #{victim == "none" ? "nobody".bold : R.penn_name(p).bold}."
  end

  def self.view(ticket)
    tz = GAME_TIME
    tz = R.xget(R["enactor"],"TZ").to_i if R.hasattr(R["enactor"],"TZ").to_bool
    t = Ticket.where(number: ticket).first
    isadmin = R.orflags(R["enactor"],"Wr").to_bool
    return ">".bold.cyan + " Invalid ticket!" unless (!t.nil? && (t.requester == R["enactor"] || isadmin))
    ret = titlebar("Ticket #{t.number.to_s}: #{t.title[0..60]}") + "\n"
    ret << "Requester: ".cyan + R.penn_name(t.requester || "")[0..20].ljust(20)
    ret << "Opened:  ".cyan + t.opened.in_time_zone(tz).strftime("%m/%d/%y %H:%M").ljust(20)
    ret << "Status: ".cyan + (t.status == "open" ? "Open".bold.on_blue : "Closed".green ) + "\n"
    if isadmin
      ret << "Assigned:  ".cyan + (t.assignee ? R.penn_name(t.assignee)[0..20].ljust(20) : "None".ljust(20))
    else
      ret << "Assigned:  ".cyan + (t.assignee ? "Yes".ljust(20) : "No".ljust(20))
    end
    ret << "Updated: ".cyan + (t.updated ? t.updated.in_time_zone(tz).strftime("%m/%d/%y %H:%M").ljust(20) : "Never".ljust(20)) + "\n"
    ret << middlebar("BODY") + "\n"
    ret << t.body + "\n"
    comments = t.comments
    if !isadmin
      comments = comments.where(private: false)
    end
    if comments.length > 0
      ret << middlebar("COMMENTS") + "\n"
      comments.desc("timestamp").each do |c|
        if c.private
          ret << "ADMIN-".bold.red
        end
        ret << "#{R.penn_name(c.author).white.bold} at #{c.timestamp.in_time_zone(tz).strftime("%m/%d/%y %H:%M").bold}: " .cyan
        ret << c.text << "\n"
      end
    end
    ret << footerbar
    ret
  end

  def self.comment(ticket,comment,privacy = true)
    t = Ticket.where(number: ticket).first
    return ">".bold.cyan + " Invalid ticket!" unless (!t.nil? && (t.requester == R["enactor"] || R.orflags(R["enactor"],"Wr").to_bool))
    t.comments.create!(author: R["enactor"], text: comment, private: privacy)
    t.updated = DateTime.now
    t.save
    team_notify("#{R.penn_name(R["enactor"]).bold} has added an #{privacy ? "admin-" : ""}comment to ticket ##{t.number.to_s.bold.yellow}.")
    if(!privacy && R["enactor"] != t.requester)
      R.pemit(t.requester,">".bold.cyan + " #{R.penn_name(R["enactor"]).bold} has added a new comment to +ticket ##{t.number.to_s.bold.yellow}. You can review it via #{("+ticket/view " + t.number.to_s).bold}.")
    end
    ">".bold.cyan + " Added comment to ticket #{t.number.to_s.bold}."
  end

  def self.close(ticket)
    t = Ticket.where(number: ticket).first
    return ">".bold.cyan + " Invalid ticket!" unless (!t.nil? && (t.requester == R["enactor"] || R.orflags(R["enactor"],"Wr").to_bool))
    return ">".bold.cyan + " Ticket already closed!" unless t.status == "open"
    t.updated = DateTime.now
    t.status = "closed"
    t.save
    t.comments.create!(author: R["enactor"], text: "Ticket closed.", private: false)
    team_notify("#{R.penn_name(R["enactor"]).bold} has closed ticket ##{t.number.to_s.bold.yellow}.")
    if R["enactor"] != t.requester
      R.objeval("#17","mailsend(#{t.requester},+Ticket #{t.number.to_s} Closed/Your +ticket #[ansi(hy,#{t.number.to_s})] has been closed. Please review any comments via [ansi(h,+ticket/view #{t.number.to_s})]. If the matter is still not resolved\\, please add a new comment using [ansi(h,+ticket/comment #{t.number.to_s}=<your notes>)] and [ansi(h,+ticket/reopen #{t.number.to_s})].)")
    end
    ">".bold.cyan + " Closed ticket #{t.number.to_s.bold}."
  end

  def self.reopen(ticket)
    t = Ticket.where(number: ticket).first
    return ">".bold.cyan + " Invalid ticket!" unless (!t.nil? && (t.requester == R["enactor"] || R.orflags(R["enactor"],"Wr").to_bool))
    return ">".bold.cyan + " Ticket already open!" unless t.status == "closed"
    t.updated = DateTime.now
    t.status = "open"
    t.save
    t.comments.create!(author: R["enactor"], text: "Ticket reopened.", private: false)
    team_notify("#{R.penn_name(R["enactor"]).bold} has reopened ticket ##{t.number.to_s.bold.yellow}.")
    ">".bold.cyan + " Reopened ticket #{t.number.to_s.bold}."
  end

  ## internal functions

  # notify admin about ticket system activity
  def self.team_notify(message)
    R.cemit("Ticket",message.cyan,"1")
  end

  # Given a Mongoid criteria, a title, and a page number, return a ticket list.
  def self.list_output(criteria, title, page = 1, show_assigned = false, sort_type = :opened)
    ret = titlebar(title + " (Page #{page})") + "\n"
    ret << "#### #{"Requester".ljust(15)} S Assign Opened   Updated  Title".cyan + "\n"
    criteria.desc(:status).desc(sort_type).skip(20 * (page.to_i - 1)).limit(20).each do |t|
      ret << t.number.to_s.rjust(4).yellow.bold + " "
      ret << R.penn_name(t.requester ||= "")[0...15].ljust(16)
      ret << (t.status == "open" ? "O".bold.on_blue + " " : "C ".green)
      ret << (t.assignee ? (show_assigned ? R.penn_name(t.assignee)[0...6].ljust(7) : "Yes    ") : "       ")
      ret << t.opened.strftime("%m/%d/%y ").cyan
      ret << (t.updated.nil? ? "         " : t.updated.strftime("%m/%d/%y "))
      ret << t.title[0..30]
      ret << "\n"
    end
    if sort_type != :opened
      ret << "\nSorted by: ".cyan + sort_type.to_s.capitalize + "\n"
    end
    ret << footerbar()
    ret
  end

  class Ticket
    include Mongoid::Document
    field :number, :type => Integer, :default => lambda {Counters.next("ticket")}
    index :number, :unique => true
    field :title, :type => String
    field :body, :type => String
    field :assignee, :type => String
    index :assignee
    field :requester, :type => String
    index :requester
    field :status, :type => String, :default => "open"
    field :opened, :type => DateTime, :default => lambda { DateTime.now }
    field :updated, :type => DateTime

    embeds_many :comments, :class_name => "Ticket::Comment"
  end

  class Comment
    include Mongoid::Document
    embedded_in :tickets, :class_name => "Ticket::Ticket"
    field :author, :type => String
    field :timestamp, :type => DateTime, :default => lambda { DateTime.now }
    field :text, :type => String
    field :private, :type => Boolean, :default => true
  end
end
