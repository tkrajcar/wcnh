require 'wcnh'

module BBoard
  
  def self.list(dbref)
    categories = Category.all.asc(:num)
    user = User.find_or_create_by(:id => dbref)
    
    ret = titlebar("Available Bulletin Board Groups") + "\n"
    ret << "##   Group Name".ljust(37).yellow + "Member?".ljust(15).yellow + "Timeout (in days)".yellow + "\n"
    ret << footerbar + "\n"
    categories.each do |i|
      next unless i.canread?(dbref)
      ret << i.num.to_s.ljust(5) + R.ansi(i.ansi, i.name.ljust(33))
      ret << (user.subscriptions.where(:category_id => i.id).first.nil? ? "No" : "Yes").ljust(20) 
      ret << (i.timeout.nil? ? "Never" : i.timeout.to_s) + "\n"
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
    
    user.subscriptions.sort{ |i, j| i.category.num <=> j.category.num }.each do |i|
      last_post = i.category.posts.desc(:created_at).first
      last_post = last_post ? last_post.created_at.strftime("%a %b %d") : "Never"
      ret << i.category.num.to_s.rjust(2) + " " + GetSymPermissions(dbref, i.category).ljust(3) + " "
      ret << R.ansi(i.category.ansi, i.category.name.ljust(30)) + last_post.ljust(21) + i.category.posts.where(:parent_id => nil).count.to_s + " "
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

    return ShowIndex(subscription, category.posts)
  end
  
  def self.read(dbref, cat, num, showreplies=false)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)

    return "> ".bold.red + "You do not subscribe to that Group." unless !category.nil?

    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "You do not subscribe to that Group." unless !subscription.nil? && category.canread?(dbref)
    
    if (num == 'u') then
      posts = (subscription.unread_posts + subscription.unread_replies.keys).uniq
      return "> ".bold.green + "No unread posts." unless posts.length > 0
      posts.each { |i| R.nspemit(dbref, DoRead(subscription, i, true)) }
      return "> ".bold.green + "All postings on Group ##{category.num} (#{category.name}) marked as read."
    end
    
    post = category.posts.where(:parent_id => nil).asc(:created_at)[num.to_i - 1]
    return "> ".bold.red + "Message #{category.num}/#{num} (#{category.name}/#{num}) does not exist." if post.nil?
    
    return DoRead(subscription, post, showreplies)
  end
  
  def self.join(dbref, cat)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)
    
    if (cat == "all") then
      Category.all.each do |i|
        if (i.canread?(dbref) && user.subscriptions.where(:category_id => i.id).first.nil?) then
          i.subscriptions.create!(:user_id => user.id)
          R.nspemit(dbref, "> ".bold.green + "You have joined the #{i.name} board.")
        end
      end
      return "> ".bold.green + "You have joined all available bboard groups."
    end
    
    return "> ".bold.red + "Sorry, you don't have access to that board." unless !category.nil? && category.canread?(dbref)
    
    subscription = user.subscriptions.where(:category_id => category.id).first
    
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
  
  def self.catchup(dbref, cat)
    user = User.find_or_create_by(:id => dbref)
    
    if (cat == "all") then
      user.subscriptions.each do |i|
        i.category.posts.each do |j|
          i.read_posts << j.id if i.read_posts.find_index(j.id).nil?
        end
        i.save
      end
      
      return "> ".bold.green + "All postings on all boards marked as read."
    end
   
    category = FindCategory(cat)
    return "> ".bold.red + "You do not subscribe to that Group." unless !category.nil?
    
    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "You do not subscribe to that Group." unless !subscription.nil? && category.canread?(dbref)
    
    category.posts.each do |i|
      subscription.read_posts << i.id if subscription.read_posts.find_index(i.id).nil?
    end
    
    subscription.save
    return "> ".bold.green + "All postings on Group ##{category.num} (#{category.name}) marked as read."
  end
  
  def self.next(dbref)
    user = User.find_or_create_by(:id => dbref)
    
    found = nil
    
    user.subscriptions.each do |sub|
      next if sub.read_posts.count == sub.category.posts.count
      sub.category.posts.each do |post|
        if sub.read_posts.find_index(post.id).nil? then
          found = post
          break
        end
      end
      break if !found.nil?
    end
    
    return "> ".bold.red + "There are no unread postings on the Global Bulletin Board." if found.nil?
    
    postnum = found.category.posts.where(:parent_id => nil).asc(:created_at).find_index { |i| i[:_id].to_s == (found.parent_id.nil? ? found.id : found.parent_id).to_s } + 1

    return read(dbref, found.category.num, postnum, (found.parent_id.nil? ? false : true))
  end
  
  def self.scan(dbref)
    user = User.find_or_create_by(:id => dbref)
    found = false
    
    ret = titlebar('Unread Postings on the Global Bulletin Board') + "\n"
    
    user.subscriptions.each do |sub|
      uposts = sub.unread_posts
      ureplies = sub.unread_replies
      unread_indexes = []
      
      next if (uposts.length == 0 && ureplies.length == 0)
      found = true
      
      ret << sub.category.name + " (#{sub.category.num}): "
      ureplies_count = 0
      ureplies.values.each { |i| ureplies_count += i.length }
      ret << "#{uposts.count} posts & #{ureplies_count} replies unread: "
      
      uposts.each { |i| unread_indexes << sub.category.posts.find_index { |j| j.id == i.id } + 1 }
      ureplies.keys.each { |i| unread_indexes << sub.category.posts.find_index { |j| j.id == i.id } + 1 }
      ret << "(#{unread_indexes.uniq.join(', ')})" + "\n"
    end
    
    return "> ".bold.red + "There are no unread postings on the Global Bulletin Board." unless found
    
    ret << footerbar
    
    return ret
  end

  def self.search(dbref, cat, term)
    user = User.find_or_create_by(:id => dbref)
    category = FindCategory(cat)

    return "> ".bold.red + "You do not subscribe to that Group." unless !category.nil?

    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "You do not subscribe to that Group." unless !subscription.nil? && category.canread?(dbref)

    found = subscription.category.posts.where(:body => Regexp.new("(?i)#{term}"))

    return "> ".bold.red + "No posts found." unless found.count > 0
    
    return ShowIndex(subscription, found)
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
  
  def self.DoRead(subscription, post, showreplies=false)
    return nil unless post
    
    index = post.category.posts.asc(:created_at).find_index { |i| i.id == post.id }
    replies = post.category.posts.where(:parent_id => post.id)
    isadmin = R.orflags(subscription.user.id, "Wr").to_bool
    
    ret = titlebar(post.category.name) + "\n"
    ret << "Message: ".yellow + "#{post.category.num}/#{index + 1}".ljust(6)
    ret << (post.sticky ? '[STICKY]' : '').ljust(13).green
    ret << "Posted                    Author".yellow + "\n"
    ret << post.title.trim_and_ljust_with_ansi(27)
    ret << post.created_at.strftime("%a %b %d @ %H:%M %Z").ljust(26)

    namestring = ""
    if post.category.anonymous.nil? || isadmin
      namestring << R.penn_name(post.author)
    else
      namestring << post.category.anonymous
    end
    namestring << "(#{post.category.anonymous})" if !post.category.anonymous.nil? && isadmin

    ret << namestring[0,25] + "\n"
    ret << middlebar('BODY') + "\n"
    ret << post.body + "\n"
    
    unread_replies = subscription.unread_replies[post] ||= []
    
    if (replies.count > 0 && showreplies == false) then
      ret << "\n" + "#{replies.count} #{(replies.count == 1 ? 'Reply' : 'Replies')} (#{unread_replies.count} Unread)".yellow + "\n"
    end
    
    subscription.read_posts << post.id if !subscription.read_posts.include?(post.id)
    subscription.save

    return ret << footerbar unless showreplies
    
    ret << middlebar("REPLIES (#{replies.count} total, #{unread_replies.count} unread)") + "\n"
    
    replies.each do |reply| 
      ret << R.penn_name(reply.author).bold.white + " at ".cyan + reply.created_at.strftime("%m/%d/%y %H:%M").to_s.bold.cyan + ": ".cyan
      ret << reply.body + "\n"
      subscription.read_posts << reply.id if !subscription.read_posts.include?(reply.id)
    end
    
    subscription.save
  
    return ret << footerbar
  end

  def self.ShowIndex(subscription, list)
    category = subscription.category
    isadmin = R.orflags(subscription.user.id, "Wr").to_bool
    index = category.posts.where(parent_id: nil).asc(:created_at)

    ret = titlebar("Index: #{category.name}") + "\n"
    ret << "        Message".ljust(43).yellow + "Posted     Replies  By".yellow + "\n"
    ret << footerbar + "\n"
    
    unread_replies = subscription.unread_replies
    list.where(:parent_id => nil).asc(:created_at).each do |post|
      replies = index.where(parent_id: post.id)

      numstring = "#{category.num}/#{index.find_index(post) + 1}"
      numstring << (!unread_replies[post].nil? ? "R" : " ")
      numstring << (!subscription.read_posts.include?(post.id) ? "U" : " ")

      ret << numstring.ljust(8)
      ret << '[STICKY] '.green if post.sticky
      ret << post.title.trim_and_ljust_with_ansi(post.sticky ? 25 : 34)
      ret << post.created_at.strftime("%a %b %d").ljust(14)
      ret << replies.count.to_s.ljust(6)

      namestring = ""
      if category.anonymous.nil? || isadmin
        namestring << R.penn_name(post.author)
      else
        namestring << category.anonymous
      end
      namestring << "(#{category.anonymous})" if !category.anonymous.nil? && isadmin

      ret << namestring[0,16]
      ret << "\n"
    end
    ret << footerbar
  end
  
end
