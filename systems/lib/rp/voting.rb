require 'wcnh'

module RP
  def self.vote(num, voter)
    return "> ".bold.red + "Invalid post number." unless item = Item.where(:num => num).first
    
    range = DateTime.now - 24.hours..DateTime.now
    if (item.votes.where(:created_at => range, :voter => voter).count > 0) then
      return "> ".bold.red + "You can only vote for a post once every 24 hours."
    end
    
    return "> ".bold.red + "Error while creating vote." unless item.votes.create!(:voter => voter)
    return "> ".bold.green + "You voted for post ##{item.num} entitled '#{item.title}'."
  end
  
  def self.decay
    decayed = 0
    destroyed = 0
    
    Item.all.each do |i|
      if (i.votes.where(:created_at.lt => DateTime.now - 3.days).count > 0) then
        i.votes.first.destroy
        i.save
        decayed += 1
      elsif (i.votes.count == 0 && i.created_at < DateTime.now - 3.days && !i.sticky) then
        i.destroy
        destroyed += 1
      end
    end
    
    Logs.log_syslog("RP", "Decay cycle ran with #{decayed} votes decayed and #{destroyed} posts removed.")
  end
  
  def self.sticky(num)
    return "> ".bold.red + "Invalid post number." unless item = Item.where(:num => num).first
    return "> ".bold.red + "Post ##{item.num} is already sticky." if item.sticky
    item.sticky = true
    item.save
    return "> ".bold.green + "Post ##{item.num} entitled '#{item.title}' is now sticky."
  end
  
  def self.unstick(num)
    return "> ".bold.red + "Invalid post number." unless item = Item.where(:num => num).first
    return "> ".bold.red + "Post ##{item.num} is not sticky." if !item.sticky
    item.sticky = false
    item.save
    return "> ".bold.green + "Post ##{item.num} entitled '#{item.title}' is no longer sticky."
  end
  
end