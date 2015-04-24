require 'wcnh'

module Shiprace

  MAX_RACERS = 10
  RACE_OBJ = "#639"
  RACE_CHAN = "100.00"
  RACE_HANDLE = "ESRL Announcer"
  RACE_TAKE = 0.15
  FILE_SHIPS = File.expand_path('./ships.txt', File.dirname(__FILE__))
  FILE_NAMES = File.expand_path('./names.txt', File.dirname(__FILE__))

  def self.purchase(dbref, skill=0, wager=10, position=0)
    race = Race.all.last
    wallet = Econ::Wallet.find_or_create_by(id: dbref)
    max_tickets = skill
#    weights = race.racers.map { |racer| racer.weight(self.build_weights(skill)) }

    return "> ".red + "Betting is currently closed." unless race.racers.count > 0
    return "> ".red + "You need at least #{wager}c to place that bet." unless wallet.balance > wager
    return "> ".red + "You cannot purchase any more tickets." unless Ticket.where(dbref: dbref).length < max_tickets
    return "> ".red + "Wager must be at least 10c." unless wager >= 10

    unless position > 0
      racer = race.racers.shuffle.first
    else
      return "> ".red + "Invalid racer.  Select between position 1 and #{race.racers.count}." unless racer = race.racers[position - 1]
    end
    
    ticket = racer.tickets.create!(dbref: dbref, wager: wager)
    race.tickets << ticket
    race.save
    
    wallet.balance -= wager
    wallet.save

    Logs.log_syslog("SHIPRACE","#{R.penn_name(R["enactor"])} purchased a race ticket with a #{wager}c wager.")
    return "> ".green + "You placed a bet of #{wager}c on the #{racer.ship.name} piloted by #{racer.name}."
  end

  def self.build_weights(skill)
    case skill
        when 2
          hash = {1 => 3, 2 => 3, 3 => 2, 4 => 2, 5 => 1, 6 => 1}
        when 3
          hash = {1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 1, 6 => 1}
        when 4
          hash = {1 => 1, 2 => 2, 3 => 3, 4 => 3, 5 => 2, 6 => 1}
        when 5
          hash = {1 => 1, 2 => 1, 3 => 2, 4 => 2, 5 => 3, 6 => 3}
        when skill > 5
          hash = {1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6}
        else
          hash = {1 => 6, 2 => 5, 3 => 4, 4 => 3, 5 => 2, 6 => 1}
        end
    
    return hash
  end
  
  def self.tickets
    tickets = Ticket.all
    
    return "> ".red + "No tickets purchased in the current race." unless tickets.count > 0
    
    ret = titlebar("Race Tickets Purchased") + "\n"
    ret << " Buyer(Gambling)".ljust(23).yellow + "Ship".ljust(24).yellow + "Pilot(Skill)".ljust(20).yellow + "Wager".yellow + "\n"
    
    tickets.each do |ticket|
      player_skill = R.u("#112/fn.get.skill", ticket.dbref, "gambling").to_i
      ret << " #{R.penn_name(ticket.dbref)}(#{player_skill})".ljust(23)
      ret << ticket.racer.ship.name.ljust(24)
      ret << "#{ticket.racer.name}(#{ticket.racer.skill})".ljust(20) 
      ret << ticket.wager.to_s + "\n"
    end
    
    ret << footerbar
    ret
  end

  def self.build_race
    race = Race.create!
    
    names = File.open(FILE_NAMES, 'r') { |file| file.readlines }
    names.each { |name| name.chomp! }
    names.shuffle!
    
    ships = File.open(FILE_SHIPS, 'r') { |file| file.readlines }
    ships.each { |ship| ship.chomp! }
    ships.shuffle!
    
    MAX_RACERS.times do
      racer = Racer.where(name: racer_name = names.pop(2).join(' ')).first
      ship = Ship.where(name: ship_name = ships.pop).first
      
      if racer.nil? && ship.nil?
        racer = race.racers.create!(name: racer_name)
        ship = racer.create_ship(name: ship_name)
      elsif !racer.nil?
        race.racers << racer
        ship = racer.ship
      else 
        race.racers << ship.racer
        racer = ship.racer
      end
      
      p "#{racer.name} flying the #{ship.name}."
    end
    
    return race
  end

  def self.roster
    race = Race.all.last
    roster = race.racers
    bank = Econ::Wallet.find_or_create_by(id: RACE_OBJ)
    tickets = Ticket.where(dbref: R["enactor"]).asc(:racer_id)
    
    return "> ".red + "The race roster is currently empty." unless roster.length > 0
    
    ret = titlebar("Racing League Roster") + "\n"
    ret << " ## Ship".ljust(35).yellow + "Pilot".ljust(25).yellow + "Odds".yellow + "\n"
    
    roster.each_with_index do |racer, num|
      ret << " #{num.next.to_s.ljust(2)} #{racer.ship.name.ljust(30)} #{racer.name.ljust(24)} #{race.odds(racer).to_frac_odds}\n"
    end
    
    if tickets.count > 0
      ret << middlebar("Your Wagers") + "\n"
      ret << "Ship".ljust(35).yellow + "Pilot".ljust(25).yellow + "Wager".yellow + "\n"
      
      tickets.each do |ticket|
        ret << ticket.racer.ship.name.ljust(35)
        ret << ticket.racer.name.ljust(25)
        ret << ticket.wager.to_s
        ret << "\n"
      end
    end
    
    ret << footerbar
    ret
  end

  def self.runrace
    race = Race.all.last
    racers = race.racers.sort { |a, b| a.skillcheck <=> b.skillcheck }.reverse
    turn1, turn2 = racers.shuffle.first, racers.shuffle.first
    victor = racers.first
    victor_odds = race.odds(victor)
    winners = victor.tickets
    total_winnings = 0
    bank = Econ::Wallet.find_or_create_by(id: RACE_OBJ)
    
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"Welcome to the Enigma Sector Racing League!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"We have #{racers.length} competitors in tonight's race through the Damioyn System!  Use race/roster to check the roster!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"3.. 2.. 1.. And they're off!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"As they pass Damioyn III, #{turn1.name} in the #{turn1.ship.name} is in the lead!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"#{turn2.name} in the #{turn2.ship.name} is leading the pack as they pass Damioyn VI!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"At the Damioyn VIII finish line, it's the #{victor.ship.name} piloted by #{victor.name}!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"#{winners.length} winning tickets paid out at #{victor_odds.to_frac_odds} odds!")

    if winners.length > 0
      winning_players = winners.map { |winner| R.penn_name(winner.dbref) }.uniq
      Logs.log_syslog("SHIPRACE", "Completing race. #{winners.length} winners: #{winning_players.itemize}")
    else
      Logs.log_syslog("SHIPRACE", "Completing race.  No winners.")
    end
    
    winners.each do |winner|
      wallet = Econ::Wallet.find_or_create_by(id: winner.dbref)
      winnings = (winner.wager * victor_odds).to_i
      
      wallet.balance += winnings
      wallet.save
      total_winnings += winnings
      R.mailsend(winner.dbref,"Ship Race Winner!/You won #{winnings} credits at #{victor_odds.to_frac_odds} odds in a ship race by betting on the #{victor.ship.name} piloted by #{victor.name}!")
    end
    
    bank.balance += race.balance - total_winnings
    bank.save
    Logs.log_syslog("SHIPRACE", "Ticket purchases: #{race.balance}.  Total payout: #{total_winnings}.  Net profit: #{race.balance - total_winnings}.")

    Ticket.destroy_all
    race.completed = true
    race.order = racers.map { |racer| racer.id }
    race.save
    self.build_race

    return
  end
  
  def self.history
    races = Race.where(completed: true).desc(:updated_at).limit(10)
    
    ret = titlebar('Racing League Recent History') + "\n"
    ret << 'Date'.ljust(13).yellow + 'First'.ljust(21).yellow + 'Second'.ljust(21).yellow + 'Third'.yellow + "\n"
    
    races.each do |race|
      ret << race.updated_at.strftime("%m/%d/%Y").ljust(13)
      ret << Racer.where(_id: race.order.first).first.name.ljust(21)
      ret << Racer.where(_id: race.order[1]).first.name.ljust(21)
      ret << Racer.where(_id: race.order[2]).first.name
      ret << "\n"
    end
    
    ret << footerbar
    ret
  end
  
  def self.record(racer)
    return '> '.red + 'No such racer.' unless racer = Racer.where(name: Regexp.new("(?i)#{racer}")).first
    
    ret = titlebar("Race History: #{racer.name} in the #{racer.ship.name}") + "\n"
    ret << 'Date'.ljust(13).yellow + 'Finish'.yellow + "\n"
    
    racer.races.where(completed: true).desc(:updated_at).limit(10).each do |race|
      ret << race.updated_at.strftime("%m/%d/%Y").ljust(15)
      ret << (race.order.find_index(racer.id) + 1).to_s
      ret << "\n"
    end
    
    ret << footerbar
    ret
  end

end

