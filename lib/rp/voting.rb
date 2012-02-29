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
      elsif (i.votes.count == 0 && i.created_at < DateTime.now - 3.days) then
        i.destroy
        destroyed += 1
      end
      
      return "#{decayed} decayed and #{destroyed} destroyed."
    end
  end
  
end