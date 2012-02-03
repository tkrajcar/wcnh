require 'wcnh'

module XP
  R = PennJSON::Remote

  def self.view(target)
    player = R.pmatch(target)
    return ">".bold.yellow + " Invalid target!" unless player != "#-1"
    ret = titlebar("Experience Log: #{R.penn_name(player)}") + "\n"
    ret << "Date      Old  New  Chg Reason\n".cyan
    logs = Log.where(player: player).desc(:timestamp).limit(15)
    logs.each do |log|
      change_output = log.change.to_s
      if log.change > 0
        change_output = "+#{log.change}"
      end
      ret << "#{log.timestamp.strftime("%m/%d/%y").cyan} #{log.old_total.to_s.rjust(4).yellow} #{log.new_total.to_s.rjust(4).yellow} #{change_output.rjust(4).bold.yellow} #{log.description[0...55].bold}\n"
    end
    ret << footerbar()
  end

  def self.award(target,quantity,reason)
    victim = R.pmatch(target)
    return ">".bold.yellow + " Invalid target!" unless victim != "#-1"
    change = quantity.to_i
    old_total = R.default("#{victim}/char`xp`total", "0").to_i
    old_available = R.default("#{victim}/char`xp`available", "0").to_i
    new_total = old_total + change
    new_available = old_available + change
    awarded_by = R["enactor"]
    R.attrib_set("#{victim}/char`xp`total", new_total.to_s)
    R.attrib_set("#{victim}/char`xp`available", new_available.to_s)
    Log.create!(player: victim, awarded_by: awarded_by, description: reason, change: change, old_total: old_total, new_total: new_total)
    R.objeval("#18", "mailsend(#{victim},XP Award/You have received an award of #{change.to_s.bold.yellow} XP from #{R.penn_name(awarded_by).bold} for: #{reason}")
    Logs.log_syslog("XPAWARD","#{R.penn_name(awarded_by)} awarded #{change.to_s} XP to #{R.penn_name(victim)} for: #{reason}")
    return ">".bold.yellow + " Awarded #{change} XP to #{R.penn_name(victim)} for: #{reason}"
  end

  def self.add_nom(target,reason)
    remaining = R.default("#{R["enactor"]}/char`noms","0").to_i
    return ">".bold.yellow + " You don't have any +noms remaining to give this week. +noms cycle weekly on Sunday evenings." unless remaining > 0
    victim = R.pmatch(target)
    return ">".bold.yellow + " That doesn't seem to be an approved player." unless R.xget(victim,"char`approved").to_i > 0
    return ">".bold.yellow + " You can't +nom yourself!" unless victim != R["enactor"]
    already_nommed = Nomination.where(author: R["enactor"], processed: false).collect(&:victim)
    return ">".bold.yellow + " You've already +nommed that person this week!" if already_nommed.include?(victim)

    Logs.log_syslog("+NOM","#{R.penn_name(R["enactor"])} +nommed #{R.penn_name(victim)} for: #{reason}")
    Nomination.create!(author: R["enactor"], victim: victim, message: reason)
    R.attrib_set("#{R["enactor"]}/char`noms",(remaining - 1).to_s)
    ">".bold.yellow + " Roleplay +nom entered for #{R.penn_name(victim).bold.white}."
  end

  def self.nom_view(target)
    player = R.pmatch(target)
    return ">".bold.yellow + " Invalid target!" unless player != "#-1"
    remaining = R.default("#{player}/char`noms","0").to_i
    ret = titlebar("Unprocessed +Nominations Entered By #{R.penn_name(player)}") + "\n"
    Nomination.where(author: player, processed: false).each do |nom|
      ret << "#{R.penn_name(nom.victim).bold.white}: #{nom.message}\n"
    end
    ret << "\n" + "You have #{remaining.to_s.bold.yellow} +nom#{remaining != 1 ? "s" : ""} remaining to give prior to Sunday at 1AM game time.\n"
    return ret << footerbar()
  end

  def self.run_noms
    Logs.log_syslog("+NOM","Running awards.")
    total = Hash.new
    nommers = []
    Nomination.where(processed: false).each do |nom|
      nommers << nom.author
      total[nom.victim] ||= 0
      total[nom.victim] += 1
      nom.processed = true
      nom.save
    end
    total.each do |player,noms|
      # award 3 xp per nom if total is <=100, 2 otherwise
      victim_total_xp = R.default("#{player}/char`xp`total","0").to_i
      if victim_total_xp > 200
        amount = noms * 4
      else
        amount = noms * 6
      end
      self.award(player,amount,"#{noms} roleplay +nom#{noms != 1 ? "s" : ""} for #{DateTime.now.strftime("%m/%d/%y")}")
    end
    
    # set new noms remaining for everyone who +nommed
    nommers.uniq.each do |nommer|
      days = Logs::Roleplay.where(:who => nommer, :timestamp.gte => 7.days.ago).collect { |pose| pose.timestamp.day}
      newnoms = [1 + days.uniq.count, 5].min # only can get up to 5 noms per week, but everybody gets at least 1
      Logs.log_syslog("+NOM","#{R.penn_name(nommer)} has poses on: #{days.uniq.to_s} so is receiving #{newnoms} new noms.")
      R.attrib_set("#{nommer}/CHAR`NOMS",newnoms.to_s)
    end
    ""
  end

  def self.run_activity
    Logs.log_syslog("XP","Running daily activity.")
    roleplayers = Hash.new
    Logs::Roleplay.where(:timestamp.gte => 1.day.ago).each do |pose|
      roleplayers[pose.who] ||= 0
      roleplayers[pose.who] += 1
    end
    roleplayers.each do |person,posecount|
      Logs.log_syslog("XP","#{R.penn_name(person)}(#{person}) had #{posecount} poses.")

      next unless posecount >= 3 # no activity XP unless you have 3 or more poses in the day
      person_total_xp = R.default("#{person}/char`xp`total","0").to_i
      if person_total_xp > 200
        amount = 1
      else
        amount = 2
      end
      self.award(person,amount,"RP activity on #{1.day.ago.strftime("%m/%d/%y")}")
    end
    ""
  end

  class Nomination
    include Mongoid::Document
    field :timestamp, :type => DateTime, :default => lambda {DateTime.now}
    field :processed, :type => Boolean, :default => false
    index :processed
    field :author, :type => String
    index :author
    field :victim, :type => String
    index :victim
    field :message, :type => String
  end

  class Log
    include Mongoid::Document
    field :timestamp, :type => DateTime, :default => lambda {DateTime.now }
    index :timestamp
    field :player, :type => String
    index :player
    field :awarded_by, :type => String
    index :awarded_by
    field :description, :type => String
    field :change, :type => Integer
    field :old_total, :type => Integer
    field :new_total, :type => Integer
  end
end
