require 'wcnh'

module BBoard
  
  def self.post(author, cat, sub, txt)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => author)

    return "> ".bold.red + "Either you do not subscribe to Group '#{cat}', or you are unable to post to it." unless !category.nil?
    
    subscription = user.subscriptions.where(:category_id => category.id).first
    post_list = category.posts.where(:parent_id => nil)
    
    return "> ".bold.red + "Either you do not subscribe to Group '#{cat}', or you are unable to post to it." unless !subscription.nil? && category.canwrite?(author)
    
    if (sub.to_i > 0 && sub.to_i <= post_list.count) then
      thread = post_list[sub.to_i - 1]
    end
    
    post = category.posts.create(
                                  :author => author, 
                                  :title => (thread.nil? ? sub : "Re: #{thread.title}"), 
                                  :body => txt, 
                                  :parent_id => (thread.nil? ? nil : thread.id)
                                  )
    
    return "> ".bold.red + post.errors.values.join(" ") unless post.valid?
    
    post.save
    online = R.lwho()
    notified = category.subscriptions.where(:user_id.in => online.split(' '))
    author_name = (category.anonymous.nil? ? R.penn_name(user.id) : category.anonymous)
    
    if (thread.nil?) then
      postnum = category.posts.where(:parent_id => nil).count
      notified.each do |i|
        R.nspemit(i.user.id, "(New BB message (#{category.num}/#{postnum}) posted to #{category.name} by #{author_name}: #{post.title})")
      end
      return "> ".bold.green + "You post your note about '#{sub}' in group #{category.num} (#{category.name}) as message ##{postnum}."
    else
      postnum = category.posts.find_index(thread) + 1
      notified.each do |i|
        R.nspemit(i.user.id, "(New BB reply posted under message ##{postnum} in group #{category.num} by #{author_name}: #{post.title})")
      end
      return "> ".bold.green + "You post your reply, '#{post.title}', under message ##{postnum} in group #{category.num} (#{category.name})."
    end
    
  end
  
  def self.draft_start(dbref, cat, sub)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)
    
    return "> ".bold.red + "Either you do not subscribe to Group '#{cat}', or you are unable to post to it." unless !category.nil?
    
    subscription = user.subscriptions.where(:category_id => category.id).first
    post_list = category.posts.where(:parent_id => nil)
    
    return "> ".bold.red + "Either you do not subscribe to Group '#{cat}', or you are unable to post to it." unless !subscription.nil? && category.canwrite?(dbref)
    return "> ".bold.red + "You are already in the middle of writing a bbpost." unless user.draft.nil?
    
    if (sub.to_i > 0 && sub.to_i <= post_list.count) then
      thread = post_list[sub.to_i - 1]
    end
    
    draft = user.create_draft(
                              :category_id => category.id, 
                              :title => (thread.nil? ? sub : "Re: #{thread.title}"), 
                              :parent_id => (thread.nil? ? nil : thread.id)
                              )
    
    return "> ".bold.red + draft.errors.values.join(" ") unless draft.valid?
    
    draft.save
    if (thread.nil?) then
      return "> ".bold.green + "You start your posting to Group ##{category.num} (#{category.name})."
    else 
      return "> ".bold.green + "You start your reply to message ##{sub.to_i} in group #{category.num} (#{category.name})."
    end
  end
  
  def self.draft_write(dbref, txt)
    user = User.find_or_create_by(:id => dbref)
    
    return "> ".bold.red + "You do not have a bbpost in progress." if user.draft.nil?
    
    user.draft.body = (user.draft.body.nil? ? txt : user.draft.body + txt)
    user.draft.save
    return "> ".bold.green + "Text added to bbpost."
  end
  
  def self.draft_proof(dbref)
    user = User.find_or_create_by(:id => dbref)
    
    return "> ".bold.red + "You do not have a bbpost in progress." if user.draft.nil?
    
    category = Category.where(:_id => user.draft.category_id).first
    
    ret = titlebar("BB Post#{user.draft.parent_id.nil? ? ' ' : 'Reply'} in Progress") + "\n"
    ret << "Group: #{category.name}" + "\n"
    ret << "Title: #{user.draft.title}" + "\n"
    ret << footerbar + "\n"
    ret << (user.draft.body.nil? ? "" : user.draft.body) + "\n"
    ret << footerbar
    
    return ret
  end
  
  def self.draft_toss(dbref)
    user = User.find_or_create_by(:id => dbref)
    
    return "> ".bold.red + "You do not have a bbpost in progress." if user.draft.nil?
    
    user.draft.destroy
    return "> ".bold.green + "Your bbpost has been discarded."
  end
  
  def self.draft_post(dbref)
    user = User.find_or_create_by(:id => dbref)
    
    return "> ".bold.red + "You do not have a bbpost in progress." if user.draft.nil?
    if user.draft.body.nil? then
      return "> ".bold.red + "Your post is empty.  Please add text with the '+bbwrite <text>' command or discard the posting with the '+bbtoss' command."
    end
    
    category = Category.where(:_id => user.draft.category_id).first
    
    thread = (user.draft.parent_id.nil? ? nil : category.posts.where(:_id => user.draft.parent_id).first)
    
    ret = post(
              user.id, # User
              category.name, # Board name
              (thread.nil? ? user.draft.title : category.posts.find_index(thread) + 1), # Draft title or Postnum of thread 
              user.draft.body, # Post body
              )
              
    user.draft.destroy
    return ret  
  end
  
  def self.remove(dbref, cat, num)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)

    return "> ".bold.red + "You do not subscribe to that Group." unless !category.nil?

    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "You do not subscribe to that Group." unless !subscription.nil? && category.canread?(dbref)
    
    post = category.posts.where(:parent_id => nil).asc(:created_at)[num.to_i - 1]
    
    return "> ".bold.red + "Message #{category.num}/#{num} (#{category.name}/#{num}) does not exist." if post.nil?
    return "> ".bold.red + "You were not the original poster of message #{num}." unless (R.orflags(dbref, "Wr").to_bool || post.author == dbref)
    return "> ".bold.red + "That post is sticky.  The sticky flag must be removed before the post can be deleted." unless (post.sticky == false)
    
    replies = category.posts.where(:parent_id => post.id)
    replies.each { |i| i.delete }
    post.delete
    
    return "> ".bold.green + "Message #{num} and #{replies.count} replies were removed from group #{category.num} (#{category.name})."
  end
  
  def self.edit(dbref, cat, num, txt, rep)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)

    return "> ".bold.red + "You do not subscribe to that Group." unless !category.nil?

    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "You do not subscribe to that Group." unless !subscription.nil? && category.canread?(dbref)
    
    post = category.posts.where(:parent_id => nil).asc(:created_at)[num.to_i - 1]
    
    return "> ".bold.red + "Message #{category.num}/#{num} (#{category.name}/#{num}) does not exist." if post.nil?
    return "> ".bold.red + "You were not the original poster of message #{num}." unless (R.orflags(dbref, "Wr").to_bool || post.author == dbref)
    
    edited = post.body.gsub(txt, rep)
    return "> ".bold.red + "No matches found." unless edited != post.body
    
    post.body = edited
    post.save
    return "> ".bold.green + "NEW TEXT: ".bold.yellow + edited.gsub(rep, rep.bold.white)
  end
  
end
