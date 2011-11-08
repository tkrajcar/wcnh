require 'wcnh'

module Ticket
  R = PennJSON::Remote

  # Open a new ticket
  def self.open(title, data)
    return ">".bold.cyan + " Sorry, guests can't open new tickets." unless !R.haspower(R["enactor"], "guest").to_bool
    t = Ticket.create!(title: title, body: data, requester: R["enactor"])
    R.cemit("Ticket", "#{R.penn_name(R["enactor"]).bold} has opened a new ticket ##{t.number.to_s.bold.yellow}: #{data}.","1")
    return ">".bold.cyan + " Ticket ##{t.number.to_s.bold} opened. Staff will respond as soon as able."
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
