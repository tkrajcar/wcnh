require 'wcnh'

module RP
  def self.create(category, title, info, creator)
    return "> ".bold.red + "Invalid category." unless cat = Category.where(:name => Regexp.new(category,1)).first
    return "> ".bold.red + "Subject cannot exceed 30 characters." unless title.length <= 30
    return "> ".bold.red + "Posting cannot exceed 1500 characters." unless info.length <= 1500
    
    return "> ".bold.red + "Error while creating post." unless item = cat.items.create!(:title => title, :info => info, :creator => creator)
    
    Logs.log_syslog("RP", "New post ##{item.num} '#{title}' in '#{cat.name}' by #{charname = R.penn_name(creator)}(#{creator}).")
    R.nscemit("Roleplay", "New +RP posting (##{item.num}) in '#{cat.name}' by #{charname} entitled '#{title}'.", 1.to_s)
    return "> ".bold.green + "Item ##{item.num} posted under '#{cat.name}'."
  end
  
  def self.view(num)
    return "> ".bold.red + "Invalid post number." unless item = Item.where(:num => num).first
    
    ret = titlebar("#{'[Sticky] ' if item.sticky}#{item.title} (#{item.votes.count} votes)")+ "\n"
    ret << "Date: ".yellow + item.created_at.strftime("%d %B %Y %H:%M %Z") + "\n"
    ret << "Author: ".yellow + R.penn_name(item.creator.to_s) + "\n"
    ret << "Category: ".yellow + item.category.name + "\n"
    ret << "\n"
    ret << item.info.to_s + "\n"
    ret << footerbar()
    
    return ret
  end
  
  def self.index(category, page=1)
    return "> ".bold.red + "Invalid category." unless cat = Category.where(:name => Regexp.new(category,1)).first
    return "> ".bold.red + "No postings in '#{cat.name}'." unless cat.items.length > 0
    
    return list("+RP Postings: #{cat.name} - Page #{page}", cat.items, page.to_i)
  end
  
  def self.search(term)
    items = Item.where(:info => Regexp.new(term))
    return "> ".bold.red + "No posts found." unless items.count > 0
    
    return list("+RP Postings: '#{term}'", items, 1) 
  end
  
  def self.top
    return list("+RP Postings: Top Posts", Item.all, 1, 10)
  end
  
  def self.toc
    ret = titlebar("+RP Postings: Category Listing") + "\n"
    ret << "Category".ljust(20).yellow + "Posts  Last Post  Description".yellow + "\n"
    Category.all.each do |i|
      ret << i.name.ljust(22) + i.items.count.to_s.ljust(5)
      ret << (i.items.count > 0 ? i.items.desc(:created_at).first.created_at.strftime("%d %b %y") : "Never").ljust(11) 
      ret << i.desc.to_s[0,40] + "\n"
    end
    ret << list("Top 5 Posts", Item.all, 1, 5) 
    
    return ret
  end
  
  def self.recent(hours)
    return "> ".bold.red + "Invalid number of hours." unless hours.to_i > 0
    range = DateTime.now - hours.to_i.hours..DateTime.now
    return list("+RP Postings: Last #{hours.to_i} Hours", Item.where(created_at: range), 1)
  end
  
  def self.list(header, criteria, page, limit=20)
    ret = titlebar(header) + "\n"
    ret << "### Title".ljust(37).yellow + "Creator".ljust(25).yellow + "Votes Posted".yellow + "\n"
    criteria.desc(:votes, :created_at).skip(20 * (page - 1)).limit(limit).each do |i|
      ret << i.num.to_s.ljust(4) + "#{'[Sticky] ' if i.sticky}#{i.title}".ljust(33) + R.penn_name(i.creator.to_s).ljust(27) + i.votes.count.to_s.ljust(4) + i.created_at.strftime("%d/%m/%Y") + "\n" 
    end
    ret << footerbar
    
    return ret
  end
  
  def self.remove(num)
    return "> ".bold.red + "Invalid post number." unless item = Item.where(:num => num).first
    if !(R.orflags(R["enactor"], "Wr").to_bool || R["enactor"] == item.creator) then
      return "> ".bold.red + "You can only remove your own posts."
    end
    return "> ".bold.red + "Error while accessing post." unless item.destroy
    
    return "> ".bold.green + "Removing post ##{item.num}."
  end
  
  def self.addcat(name)
    return "> ".bold.red + "Invalid category name." unless Category.where(:name => Regexp.new(name,1)).count == 0
    return "> ".bold.red + "Error while creating category." unless Category.create!(:name => name)
    Logs.log_syslog("RP", "#{R.penn_name(enactor = R["enactor"])}(#{enactor}) created new category '#{name}'.")
    return "> ".bold.green + "New category '#{name}' created."
  end
  
  def self.remcat(name)
    return "> ".bold.red + "No such category." unless cat = Category.where(:name => Regexp.new(name,1)).first
    cat.items.each { |i| i.votes.destroy_all}
    cat.items.destroy_all
    return "> ".bold.red + "Error while deleting category." unless cat.destroy
    Logs.log_syslog("RP", "#{R.penn_name(enactor = R["enactor"])}(#{enactor}) deleted category '#{name}'.")
    return "> ".bold.green + "Category '#{cat.name}' and all posts removed."
  end
  
  def self.desc(name, desc)
    return "> ".bold.red + "No such category." unless cat = Category.where(:name => Regexp.new(name,1)).first
    cat.desc = desc
    cat.save
    return "> ".bold.green + "Category description for '#{cat.name}' updated."
  end
end
