require 'wcnh'

module Anatomy
  
  def self.scan(dbref)
    if !(target = Body.where(:dbref => dbref).first) then
       target = raceToClass(R.xget(dbref, "char`race")).create!(:dbref => dbref)
    end
    
    ret = titlebar("Medical Status: " + R.penn_name(dbref)) + "\n"
    ret << "Region".ljust(10).yellow + "Status ".yellow + "\n"
    target.parts.each do |i|
      ret << i.name.ljust(10) + pctToInjury(i.pctHealth) + " (#{(i.pctHealth * 100).to_i}%)" + "\n"
    end 
    ret << "\n"
    ret << "Total Health: ".yellow  + pctToInjury(target.getPctHealth) + " (#{(target.getPctHealth * 100).to_i}%)" + "\n"
    ret << footerbar
  end
  
  def self.raceToClass(raceString)
    (raceString == "Kilrathi" ? Anatomy::Kilrathi : Anatomy::Human)
  end
  
  def self.pctToInjury(float)
    case float
    when 1
      "Uninjured".bold.green
    when 0.75..1
      "Light Wounds".green
    when 0.5..0.75
      "Moderate Wounds".bold.yellow
    when 0.25..0.5
      "Serious Wounds".yellow
    when 0.01..0.25
      "Critical Wounds".bold.red
    else
      "Incapacitated".red
    end
  end
  
  def self.cronHeal
    injured = Body.all.to_a.select { |i| i.getPctHealth < 1.0 }
    
    injured.each do |i|
      parts = i.doHeal
      
      i.treatments.each do |j|
        parts << j.doTreat
      end
      
      parts = parts.compact.uniq
      if parts.length > 0 then
        partnames = Array.new(parts.length) { |i| parts[i].name.downcase }
        R.nspemit(i.dbref, "The injuries to your #{partnames.itemize} are feeling a little better.".yellow)
      else
        R.nspemit(i.dbref, "None of your injuries are feeling any better.".yellow)
      end
    end
    
    Treatment.cleanup

    return 
  end
  
  def self.heal(healer, dbref, part)
    if !(target = Body.where(:dbref => dbref).first) then
       target = raceToClass(R.xget(dbref, "char`race")).create!(:dbref => dbref)
    end
    
    unless part = target.parts[target.parts.find_index { |i| i.name.downcase == part }]
      return "> ".bold.red + "Invalid body part.  'med/scan <target>' to see a list of valid parts."
    end
    
    unless part.pctHealth < 1.0
      return "> ".bold.red + "#{R.penn_name(dbref)}'s #{part.name.downcase} is uninjured.  Check 'med/scan <target>'."
    end
  end
  
end
