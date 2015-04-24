require 'wcnh'

module Anatomy
  
  def self.damage(body, part=nil, force)
# 'body' is a valid Anatomy::Body document
# 'part' is a string that will match an embedded Anatomy::Part document in the 'body' object, or leave nil for random
# 'force' is an integer amount of force to apply which will be translated into damage
# return value if successful will be the injured Anatomy::Part
    return nil unless result = body.applyDamage(force, part)
    R.nsoemit(body.dbref, "[#{'COMBAT'.bold.red}] #{R.penn_name(body.dbref)} takes a #{forceDescribe(force)} to the #{result.name.downcase}!")
    R.nspemit(body.dbref, "[#{'COMBAT'.bold.red}] #{'You'.bold.yellow} take a #{forceDescribe(force)} to the #{result.name.downcase}!")
    
# Stop here if they're already unconscious    
    return result if body.conscious == false
    
# Otherwise, see if they should go unconscious
    if (body.checkUncon == false) then
      R.nsoemit(body.dbref, "[#{'COMBAT'.bold.red}] #{R.penn_name(body.dbref)} falls unconscious!")
      R.nspemit(body.dbref, "[#{'COMBAT'.bold.red}] #{'You'.bold.yellow} go #{'unconscious'.bold.red}!")
#      R.penn_set(body.dbref, UNCONSCIOUS)
    end 
    return result
  end
  
  def self.forceDescribe(force)
    case force
    when 0..499
      "light hit".green
    when 500..999
      "medium hit".yellow
    else
      "crushing blow".bold.red
    end
  end
  
end
