require 'wcnh'

module Ticket
  R = PennJSON::Remote

  # Open a new ticket
  def self.open(title, data)
    return ">".bold.cyan + " Sorry, guests can't open new tickets." unless !R.haspower(R["enactor"], "guest").to_bool
    t = Ticket.create!(title: title, body: data, requester: R["enactor"])
    team_notify("#{R.penn_name(R["enactor"]).bold} has opened a new ticket ##{t.number.to_s.bold.yellow}: #{title.bold.white}.")
    return ">".bold.cyan + " Ticket ##{t.number.to_s.bold} opened. We'll respond as soon as possible."
  end

  def self.list(page = 1)
    page = page.to_i
    return ">".bold.cyan + " Invalid page number." unless page > 0
    if R.orflags(R["enactor"],"Wr").to_bool
      list_output(Ticket.all, "All +Tickets",page,true)
    else
      list_output(Ticket.where(requester: R["enactor"]), "Your Opened +Tickets",page,false)
    end
  end

  def self.mine(page)
    page = page.to_i
    return ">".bold.cyan + " Invalid page number." unless page > 0

    list_output(Ticket.where(assignee: R["enactor"]).where(status: "open"), "Your Assigned +Tickets", page,true)
  end

  def self.assign(ticket,victim)
    return ">".bold.cyan + " Invalid ticket!" unless t = Ticket.where(number: ticket).first
    p = R.pmatch(victim)
    return ">".bold.cyan + " Invalid assignee!" unless R.orflags(p,"Wr").to_bool || victim == "none"
    t.assignee = (victim == "none" ? nil : p)
    t.updated = DateTime.now
    t.save
    team_notify("#{R.penn_name(R["enactor"]).bold} has assigned ticket ##{t.number.to_s.bold.white} to #{victim == "none" ? "nobody".bold.yellow : R.penn_name(p).bold.yellow}.")
    ">".bold.cyan + " Ticket #{t.number.to_s.bold} assigned to #{victim == "none" ? "nobody".bold : R.penn_name(p).bold}."
  end

  def self.view(ticket)
    t = Ticket.where(number: ticket).first
    return ">".bold.cyan + " Invalid ticket!" unless (!t.nil? && (t.requester == R["enactor"] || R.orflags(R["enactor"],"Wr").to_bool))
    ret = titlebar("Ticket #{t.number.to_s}: #{t.title[0..60]}") + "\n"
    ret << "Requester: ".cyan + R.penn_name(t.requester || "")[0..20].ljust(20)
    ret << "Opened: ".cyan + t.opened.strftime("%m/%d/%y %H:%M").ljust(20)
    ret << "Status: ".cyan + (t.status == "open" ? "Open".bold.on_blue : "Closed".green ) + "\n"  
    ret << footerbar
    ret
  end


  ## internal functions

  # notify admin about ticket system activity
  def self.team_notify(message)
    R.cemit("Ticket",message.cyan,"1")
  end

  # Given a Mongoid criteria, a title, and a page number, return a ticket list.
  def self.list_output(criteria, title, page = 1, show_assigned = false)
    ret = titlebar(title + " (Page #{page})") + "\n"
    ret << "XXXX #{"Requester".ljust(15)} S Assign Opened   Updated  Title".cyan + "\n"
    criteria.desc(:status).desc(:opened).skip(20 * (page.to_i - 1)).limit(20).each do |t|
      ret << t.number.to_s.rjust(4).yellow.bold + " "
      ret << R.penn_name(t.requester ||= "")[0...15].ljust(16)
      ret << (t.status == "open" ? "O".bold.on_blue + " " : "C ".green)
      ret << (t.assignee ? (show_assigned ? R.penn_name(t.assignee)[0...6].ljust(7) : "Yes   ") : "       ")
      ret << t.opened.strftime("%m/%d/%y ").cyan
      ret << (t.updated.nil? ? "         " : t.updated.strftime("%m/%d/%y "))
      ret << t.title[0..30]
      ret << "\n"
    end
    ret << footerbar()
    ret
  end

  class Ticket
    include Mongoid::Document
    field :number, :type => Integer, :default => lambda {Counters.next("ticket")}
    field :title, :type => String
    field :body, :type => String
    field :assignee, :type => String
    field :requester, :type => String
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
  end
end
