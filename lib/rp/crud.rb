require 'wcnh'

module RP
  def self.create(category, title, info)
    return "> ".bold.red + "Invalid category." unless cat = Category.where(:name => category).first
    return "> ".bold.red + "Subject cannot exceed 30 characters." unless title.length <= 30
    return "> ".bold.red + "Posting cannot exceed 300 characters." unless info.length <= 300
    
    return "> ".bold.red + "Error while creating post." unless item = cat.items.create!(:title => title, :info => info)
    return "> ".bold.green + "Item ##{item.num} posted under '#{cat.name}'."
  end
  
  def self.view(num)
    return "> ".bold.red + "Invalid post number." unless item = Item.where(:num => num).first
    
    ret = titlebar("#{item.title} (#{item.votes} votes)")+ "\n"
    ret << "Date: ".yellow + item.created_at.to_s + "\n"
    ret << "Author: ".yellow + item.creator.to_s + "\n"
    ret << "Category:".yellow + item.category.name + "\n"
    ret << "\n"
    ret << item.info.to_s + "\n"
    ret << footerbar()
    
    return ret
  end
  
  def self.index(category, page=1)
    return "> ".bold.red + "Invalid category." unless cat = Category.where(:name => category).first
    return "> ".bold.red + "No postings in '#{cat.name}'." unless cat.items.length > 0
    
    return list("+RP Postings: #{cat.name} - Page #{page}", cat.items, page.to_i)
  end
  
  def self.search(term)
    items = Item.where(:info => Regexp.new(term))
    return "> ".bold.red + "No posts found." unless items.count > 0
    
    return list("+RP Postings: '#{term}'", items, 1) 
  end
  
  def self.top
    return list("+RP Postings: Top Posts", Item.all.limit(10), 1)
  end
  
  def self.recent(hours)
    range = DateTime.now - hours.hours..DateTime.now
    return list("+RP Postings: Last #{hours} Hours", Item.where(created_at: range), 1)
  end
  
  def self.list(header, criteria, page)
    ret = titlebar(header) + "\n"
    ret << "### Title".ljust(30).yellow + "Creator".ljust(25).yellow + "Votes Posted".yellow + "\n"
    criteria.desc(:votes, :created_at).skip(20 * (page - 1)).limit(20).each do |i|
      ret << i.num.to_s.ljust(4) + i.title.to_s.ljust(30) + i.creator.to_s.ljust(27) + i.votes.to_s.ljust(4) + i.created_at.strftime("%d/%m/%Y") + "\n" 
    end
    ret << footerbar
    
    return ret
  end
  
  def self.remove(num)
    return "> ".bold.red + "Invalid post number." unless item = Item.where(:num => num).first
    return "> ".bold.red + "Error while accessing post." unless item.destroy
    
    return "> ".bold.green + "Removing post ##{item.num}."
  end
end
