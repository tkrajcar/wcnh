require 'wcnh'

module BBoard
  
  def self.list(dbref)
    categories = Category.all
    user = User.find_or_create_by(:id => dbref)
    
    ret = titlebar("Available Bulletin Board Groups") + "\n"
    ret << "##   Group Name".ljust(37).yellow + "Member?".ljust(15).yellow + "Timeout (in days)".yellow + "\n"
    ret << footerbar + "\n"
    categories.each do |i|
      next unless i.canread?(dbref)
      ret << i.num.to_s.ljust(5) + i.name.ljust(33)
      ret << (user.subscriptions.where(:category_id => i.id).first.nil? ? "No" : "Yes").ljust(20) + i.timeout.to_s + "\n"
    end
    
    ret << footerbar + "\n"
    ret << "To join groups, type '+bbjoin <group number or name>'" + "\n"
    ret << footerbar
  end
  
  def self.toc(dbref)
    user = User.find_or_create_by(:id => dbref)
    
    ret = titlebar("Categories") + "\n"
    ret << "       Group Name".ljust(37).yellow + "Last Post      # of messages".yellow + "\n"
    ret << footerbar + "\n"
    
    user.subscriptions.each do |i|
      last_post = i.category.posts.desc(:created_at).first
      last_post = last_post ? last_post.created_at.strftime("%a %b %d") : "Never"
      ret << i.category.num.to_s.rjust(2) + " " + GetSymPermissions(dbref, i.category).ljust(3) + " "
      ret << i.category.name.ljust(30) + last_post.ljust(21) + i.category.posts.count.to_s + " "
      ret << "U" if (i.unread_posts.count > 0)
      ret << "R" if (i.unread_replies.count > 0)
      ret << "\n"
    end
    
    ret << footerbar + "\n"
    ret << "'*' = restricted     '-' = read only     '(-)' = read only, but you can write" + "\n"
    ret << footerbar
    
    return ret
  end
  
  def self.index(dbref, cat)
    user = User.find_or_create_by(:id => dbref)
    category = FindCategory(cat)

    return "> ".bold.red + "You do not subscribe to that Group." unless !category.nil?

    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "You do not subscribe to that Group." unless !subscription.nil? && category.canread?(dbref)
    
    ret = titlebar("Index: #{category.name}") + "\n"
    ret << "        Message".ljust(43).yellow + "Posted        By".yellow + "\n"
    ret << footerbar + "\n"
    
    unread_replies = subscription.unread_replies
    count = 1
    category.posts.where(:parent_id => nil).each do |post|
      ret << "#{category.num}/#{count}".ljust(5)
      ret << (!unread_replies[post.id].nil? ? "R" : " ")
      ret << (subscription.read_posts.find_index(post.id).nil? ? "U" : " ")
      ret << " " + post.title.ljust(35) + post.created_at.strftime("%a %b %d").ljust(14) + R.penn_name(post.author)
      ret << "\n"
      count += 1
    end
    ret << footerbar
    
    return ret
  end
  
  def self.read(dbref, cat, num)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)

    return "> ".bold.red + "You do not subscribe to that Group." unless !category.nil?

    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "You do not subscribe to that Group." unless !subscription.nil? && category.canread?(dbref)
    
    post = category.posts.where(:parent_id => nil)[num.to_i - 1]
    
    return "> ".bold.red + "Message #{category.num}/#{num} (#{category.name}/#{num}) does not exist." if post.nil?
    
    ret = titlebar(category.name) + "\n"
    ret << "Message: ".yellow + "#{category.num}/#{num}".ljust(17) + "Posted                    Author".yellow + "\n"
    ret << post.title.ljust(26) + post.created_at.strftime("%a %b %d @ %H:%M %Z").ljust(26) + R.penn_name(post.author) + "\n"
    ret << footerbar + "\n"
    ret << post.body + "\n"
    ret << footerbar
    
    subscription.read_posts << post.id if subscription.read_posts.find_index(post.id).nil?
    subscription.save
    
    return ret
  end
  
  def self.join(dbref, cat)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)
    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "Sorry, you don't have access to that board." unless !category.nil? && category.canread?(dbref)
    return "> ".bold.red + "You are already a member of #{category.name}." unless subscription.nil?
    
    category.subscriptions.create!(:user_id => user.id)
    return "> ".bold.green + "You have joined the #{category.name} board."
  end
  
  def self.leave(dbref, cat)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)
    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "You aren't currently subscribing to Board #{cat}." if category.nil? || subscription.nil?
    
    subscription.destroy
    return "> ".bold.green + "You have removed yourself from the #{category.name} board." 
  end
  
  def self.FindCategory(cat)
    if (cat.to_i > 0) then
      category = Category.where(:num => cat).first
    else
      category = Category.where(:name => Regexp.new("(?i)#{cat}")).first
    end
    
    return category
  end
  
  def self.GetSymPermissions(dbref, category)
    canwrite = category.canwrite?(dbref)
    canread = category.canread?(dbref)
    
    if (category.permission_type == "announce" && canwrite) then
      "(-)"
    elsif (!category.permission_type.nil? && canwrite) then
      " * "
    elsif (category.permission_type == "announce") then
      " - "
    else
      "   "
    end
  end
  
end
