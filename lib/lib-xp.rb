require 'wcnh'

module XP
  R = PennJSON::Remote

  def self.view(target)
    player = R.pmatch(target)
    return ">".bold.yellow + " Invalid target!" unless player != "#-1"
    ret = titlebar("Experience Log: #{R.penn_name(player)}") + "\n"
    ret << "Date      Old  New  Chg Reason\n".cyan
    logs = Log.where(player: target).desc(:timestamp).limit(15)
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
    return ">".bold.yellow + " Awarded #{change} XP to #{R.penn_name(victim)} for: #{reason}"
  end

  def self.add_nom(target,reason)
  end

  def self.run_noms
  end

  def self.run_activity
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
