require 'wcnh'

module BBoard
  
  def self.toc
    categories = Category.all
    
    ret = titlebar("Categories") + "\n"
    ret << "       Group Name".ljust(37).yellow + "Last Post      # of messages".yellow + "\n"
    ret << footerbar + "\n"
    
    categories.each do |i|
      last_post = i.posts.desc(:created_at).first
      last_post = last_post ? last_post.created_at.strftime("%a %b %d") : "Never"
      ret << i.num.to_s.rjust(2).ljust(7) + i.name.ljust(30) + last_post.ljust(22) + i.posts.count.to_s + "\n"
    end
    
    ret << footerbar + "\n"
    ret << "'*' = restricted     '-' = read only     '(-)' = read only, but you can write" + "\n"
    ret << footerbar
    
    return ret
  end
  
  def self.index(cat)
    if (cat.to_i > 0) then
      category = Category.where(:num => cat).first
    else
      category = Category.where(:name => Regexp.new("(?i)#{cat}")).first
    end
    
    return "> ".bold.red + "No such category." if category.nil?
    
    ret = titlebar("Index: #{category.name}") + "\n"
    ret << "        Message".ljust(43).yellow + "Posted        By".yellow + "\n"
    ret << footerbar + "\n"
    
    category.posts.each_index do |i|
      post = category.posts[i]
      ret << "#{category.num}/#{i + 1}".ljust(8) + post.title.ljust(35) + post.created_at.strftime("%a %b %d").ljust(14) + R.penn_name(post.author)
    end
    ret << "\n"
    ret << footerbar
    
    return ret
  end
  
  def self.read(cat, num)
    if (cat.to_i > 0) then
      category = Category.where(:num => cat).first
    else
      category = Category.where(:name => Regexp.new("(?i)#{cat}")).first
    end
    
    return "> ".bold.red + "No such category," if category.nil?
    
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
  
end
