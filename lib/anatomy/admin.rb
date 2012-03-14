require 'wcnh'

module Anatomy
  
  def self.injure(dbref, part=nil, damage)
    if !(target = Body.where(:dbref => dbref).first) then
       target = raceToClass(R.xget(dbref, "char`race")).create!(:dbref => dbref)
    end
    
    if (damage.to_i == 0) then 
      case damage.downcase
      when "light"
        force = 100
      when "moderate"
        force = 500
      when "heavy"
        force = 1000
      else
        return "> ".bold.red + "Invalid damage level.  Try 'light', 'moderate', 'heavy', or an integer."
      end
    else force = damage.to_i
    end
    
    return "> ".bold.red + "Invalid target bodypart.  'med/scan <target>' for a list." unless result = damage(target, part, force)
    Logs.log_syslog("COMBAT", "#{R.penn_name(R["enactor"])} +injured #{R.penn_name(dbref)}'s #{result.name.downcase} with #{force}J of force.")
    return "> ".bold.green + "#{force}J force applied to #{R.penn_name(dbref)}'s #{result.name.downcase}."
  end
  
  def self.heal_admin(dbref)
    if !(target = Body.where(:dbref => dbref).first) then
       target = raceToClass(R.xget(dbref, "char`race")).create!(:dbref => dbref)
    end
    
    target.parts.each_index { |i| target.parts[i].pctHealth = 1.0 }
    target.save
    
    Logs.log_syslog("COMBAT", "#{R.penn_name(R["enactor"])} +healed #{R.penn_name(dbref)}.")
    return "> ".bold.green + "#{R.penn_name(dbref)} healed to 100%."
  end
  
end
