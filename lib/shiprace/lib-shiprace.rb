require 'wcnh'

module Shiprace

  MAX_RACERS = 10
  RACE_OBJ = "#639"
  RACE_CHAN = "100.00"
  RACE_HANDLE = "ESRL Announcer"
  FILE_SHIPS = File.expand_path('./ships.txt', File.dirname(__FILE__))
  FILE_NAMES = File.expand_path('./names.txt', File.dirname(__FILE__))

  def self.purchase(dbref)
    wallet = Econ::Wallet.find_or_create_by(id: dbref)
    bank = Econ::Wallet.find_or_create_by(id: RACE_OBJ)
    return "> ".red + "Betting is currently closed." unless Racer.all.length > 0
    return "> ".red + "You need at least 10c to place a bet." unless wallet.balance > 10
    return "> ".red + "You cannot have more than 3 tickets for one race." unless Ticket.where(dbref: dbref).length < 3
    ticket = Ticket.create!(dbref: dbref)
    racer = Racer.all[ticket.victor]
    wallet.balance = wallet.balance - 10
    wallet.save
    bank.balance = bank.balance + 10
    bank.save
    Logs.log_syslog("SHIPRACE","#{R.penn_name(R["enactor"])} purchased a race ticket for 10c.")
    return "> ".green + "You placed a bet of 10c on the #{racer.ship} piloted by #{racer.name}"
  end

  def self.tickets
    return "> ".red + "No tickets purchased in the current race." unless tickets = Ticket.all
    racers = Racer.all
    ret = titlebar("Race Tickets Purchased") + "\n"
    ret << " Buyer".ljust(25).yellow + "Ship".ljust(25).yellow + "Pilot".yellow + "\n"
    tickets.each do |ticket|
      ret << " #{R.penn_name(ticket.dbref).ljust(23)} #{racers[ticket.victor].ship.ljust(24)} #{racers[ticket.victor].name}\n"
    end
    ret << footerbar
    ret
  end

  def self.buildroster
    names = []
    ships = []
    roster = {}

    File.open(FILE_NAMES, "r") do |file|
      while line = file.gets
        names.<< line.chomp
      end
    end

    File.open(FILE_SHIPS, "r") do |file|
      while line = file.gets
        ships.<< line.chomp
      end
    end

    ships.shuffle!
    names.shuffle!
    MAX_RACERS.times { roster["#{names.shift} #{names.shift}"] = ships.shift }
    roster.each { |name, ship| Racer.create!(name: name, ship: ship) }

    return roster.length
  end

  def self.roster
    roster = Racer.all
    return "> ".red + "The race roster is currently empty." unless roster.length > 0
    ret = titlebar("Racing League Roster") + "\n"
    ret << " ## Ship".ljust(35).yellow + "Pilot".yellow + "\n"
    roster.each_with_index do |racer, num|
      ret << " #{num.next.to_s.ljust(2)} #{racer.ship.ljust(30)} #{racer.name}\n"
    end
    ret << footerbar
    ret
  end

  def self.runrace
    racers = Racer.all
    victor, turn1, turn2 = rand(racers.length), rand(racers.length), rand(racers.length)
    winners = Ticket.where(victor: victor)
    bank = Econ::Wallet.find_or_create_by(id: RACE_OBJ)
    pot = (bank.balance * 0.75).to_i

    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"Welcome to the Enigma Sector Racing League!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"We have #{racers.length} competitors in tonight's race through the Damioyn System!  Use race/roster to check the roster!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"3.. 2.. 1.. And they're off!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"As they pass Damioyn III, #{racers[turn1].name} in the #{racers[turn1].ship} is in the lead!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"#{racers[turn2].name} in the #{racers[turn2].ship} is leading the pack as they pass Damioyn VI!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"At the Damioyn VIII finish line, it's the #{racers[victor].ship} piloted by #{racers[victor].name}!")
    Comms.channel_emit(RACE_CHAN,RACE_HANDLE,"There were #{winners.length} winning tickets with a jackpot of #{pot} credits.")

    if winners.length > 0
      bank.balance = bank.balance - pot
      bank.save
    end
    
    winners_names = []
    winners.each { |winner| winners_names.<< R.penn_name(winner) }
    Logs.log_syslog("SHIPRACE","Completing race.  Jackpot: #{pot}. #{winners.length} winners: #{winners_names.join(", ")}")

    winners.each do |winner|
      wallet = Econ::Wallet.find_or_create_by(id: winner.dbref)
      wallet.balance = wallet.balance + (pot / winners.length)
      wallet.save
      Logs.log_syslog("SHIPRACE","#{R.name(winner.dbref)} won #{pot / winners.length}c.")
      R.mailsend(winner.dbref,"Ship Race Winner!/You won #{pot / winners.length} credits in a ship race by betting on the #{racers[victor].ship} piloted by #{racers[victor].name}!")
    end

    Ticket.destroy_all
    Racer.destroy_all
    self.buildroster

    return
  end

  class Racer
      include Mongoid::Document
      field :name, type: String
      field :ship, type: String
      field :dbref, type: String
  end

  class Ticket
      include Mongoid::Document
      field :dbref, type: String
      field :victor, type: Integer, default: lambda { rand(MAX_RACERS) }
  end

end

