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
    ret << footerbar() + "\n"
    ret << item.info.to_s + "\n"
    ret << footerbar()
    
    return ret
  end
  
  def self.remove(num)
    return "> ".bold.red + "Invalid post number." unless item = Item.where(:num => num).first
    return "> ".bold.red + "Error while accessing post." unless item.destroy
    
    return "> ".bold.green + "Removing post ##{item.num}."
  end
end
