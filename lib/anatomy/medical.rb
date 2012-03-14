require 'wcnh'

module Anatomy
  
  def self.scan(dbref)
    if !(target = Body.where(:dbref => dbref).first) then
       target = raceToClass(R.xget(dbref, "char`race")).create!(:dbref => dbref)
    end
    
    ret = titlebar("Medical Status: " + R.penn_name(dbref)) + "\n"
    ret << "Region".ljust(10).yellow + "Status ".yellow + "\n"
    
    target.parts.each do |i|
      ret << i.name.ljust(10) + pctToInjury(i.pctHealth) + " (#{(i.pctHealth * 100).to_i}%)"
      if (treatment = target.treatments.find_index { |j| j.part == i.name }) then
        treatment = target.treatments[treatment]
        ret << " - Treated #{((Time.now - treatment.created_at.to_time) / 3600).to_i} hours ago by #{R.penn_name(treatment.healer)}."
      end
      ret << "\n"
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
  
  def self.cronUncon
    wakeup = []
    Body.where(:conscious => false).each do |i|
      wakeup << i.dbref if (i.checkUncon == true)
      i.save
    end
    return wakeup.to_mush
  end
  
  def self.heal(healer, dbref, part, skill_medicine, skill_firstaid)
    skill_medicine = skill_medicine.to_i
    skill_firstaid = skill_firstaid.to_i
    
    if !(target = Body.where(:dbref => dbref).first) then
       target = raceToClass(R.xget(dbref, "char`race")).create!(:dbref => dbref)
    end
    
    unless part = target.parts.find_index { |i| i.name.downcase == part }
      return "> ".bold.red + "Invalid body part. 'med/scan <target>' to see a list of valid parts."
    end
    
    part = target.parts[part]
    
    unless part.pctHealth < 1.0
      return "> ".bold.red + "#{R.penn_name(dbref)}'s #{part.name.downcase} is uninjured.  Check 'med/scan <target>'."
    end
    
    unless part.pctHealth < 0.8 && !(target.treatments.find_index { |i| i.part == part.name })
      return "> ".bold.red + "You can't do anything more for #{R.penn_name(dbref)}'s #{part.name.downcase} right now."
    end
    
    if (part.pctHealth < 0.6 && healer == dbref)
      return "> ".bold.red + "Your injuries are beyond the point of self-help."
    end
     
    case part.pctHealth
    when 0.6..0.8
      treatment = FirstAid
    when 0.4..0.6
      treatment = (skill_firstaid > skill_medicine ? FirstAid : Medicine)
    else
      treatment = Medicine
    end
    
    roll = rand(5) - 2 + (treatment == FirstAid ? skill_firstaid : skill_medicine)
    
    if (roll < 1) then
      if (roll == 0) then
        R.nsremit(R.penn_loc(healer), "[#{'COMBAT'.bold.red}] #{R.penn_name(healer)} treats #{R.penn_name(dbref)}'s #{part.name.downcase} injury but it doesn't seem to help much.")
      else 
        R.nsremit(R.penn_loc(healer), "[#{'COMBAT'.bold.red}] #{R.penn_name(healer)} attempts to treat #{R.penn_name(dbref)}'s #{part.name.downcase} injury but ends up making it worse!")
        target.applyDamage(50 * roll.abs, part.name)
      end
      target.treatments.create({healer: healer, success: 0, part: part.name}, treatment)
      target.save
      return
    else
      R.nsremit(R.penn_loc(healer), "[#{'COMBAT'.bold.red}] #{R.penn_name(healer)} successfully treats #{R.penn_name(dbref)}'s #{part.name.downcase} injury.")
      target.treatments.create({healer: healer, success: roll, part: part.name}, treatment)
      target.save
      return
    end
  end
  
end
