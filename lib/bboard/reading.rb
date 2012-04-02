require 'wcnh'

module BBoard
  
  def self.list(dbref)
    categories = Category.all
    
    ret = titlebar("Available Bulletin Board Groups") + "\n"
    ret << "##   Group Name".ljust(37).yellow + "Member?".ljust(15).yellow + "Timeout (in days)".yellow + "\n"
    ret << footerbar + "\n"
    categories.each do |i|
      ret << i.num.to_s.ljust(5) + i.name.ljust(33) + "No".ljust(20) + i.timeout.to_s + "\n"
    end
    
    ret << footerbar + "\n"
    ret << "To join groups, type '+bbjoin <group number or name>'" + "\n"
    ret << footerbar
  end
  
  def self.toc(dbref)
    categories = Category.all
    
    ret = titlebar("Categories") + "\n"
    ret << "       Group Name".ljust(37).yellow + "Last Post      # of messages".yellow + "\n"
    ret << footerbar + "\n"
    
    categories.each do |i|
      last_post = i.posts.desc(:created_at).first
      last_post = last_post ? last_post.created_at.strftime("%a %b %d") : "Never"
      ret << i.num.to_s.rjust(2).ljust(7) + i.name.ljust(30) + last_post.ljust(21) + i.posts.count.to_s + "\n"
    end
    
    ret << footerbar + "\n"
    ret << "'*' = restricted     '-' = read only     '(-)' = read only, but you can write" + "\n"
    ret << footerbar
    
    return ret
  end
  
  def self.index(dbref, cat)
    category = FindCategory(cat)
    
    return "> ".bold.red + "You do not subscribe to that Group." if category.nil?
    
    ret = titlebar("Index: #{category.name}") + "\n"
    ret << "        Message".ljust(43).yellow + "Posted        By".yellow + "\n"
    ret << footerbar + "\n"
    
    category.posts.each_index do |i|
      post = category.posts[i]
      ret << "#{category.num}/#{i + 1}".ljust(8) + post.title.ljust(35) + post.created_at.strftime("%a %b %d").ljust(14) + R.penn_name(post.author)
      ret << "\n"
    end
    ret << footerbar
    
    return ret
  end
  
  def self.read(cat, num)
    category = FindCategory(cat)
    
    return "> ".bold.red + "You do not subscribe to that Group." if category.nil?
    
    post = category.posts[num.to_i - 1]
    
    return "> ".bold.red + "Message #{category.num}/#{num} (#{category.name}/#{num}) does not exist." if post.nil?
    
    ret = titlebar(category.name) + "\n"
    ret << "Message: ".yellow + "#{category.num}/#{num}".ljust(17) + "Posted                    Author".yellow + "\n"
    ret << post.title.ljust(26) + post.created_at.strftime("%a %b %d @ %H:%M %Z").ljust(26) + R.penn_name(post.author) + "\n"
    ret << footerbar + "\n"
    ret << post.body + "\n"
    ret << footerbar
    
    return ret
  end
  
  def self.FindCategory(cat)
    if (cat.to_i > 0) then
      category = Category.where(:num => cat).first
    else
      category = Category.where(:name => Regexp.new("(?i)#{cat}")).first
    end
    
    return category
  end
  
end
