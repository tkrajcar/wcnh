require 'wcnh'

module BBoard
  
  def self.post(author, cat, sub, txt, parent)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => author)

    return "> ".bold.red + "Either you do not subscribe to Group '#{cat}', or you are unable to post to it." unless !category.nil?
    
    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "Either you do not subscribe to Group '#{cat}', or you are unable to post to it." unless !subscription.nil? && category.canwrite?(author)
    
    thread = (parent.nil? ? nil : category.posts.where(:parent_id => nil)[parent.to_i - 1])
    return "> ".bold.red + "You can't post a reply to that thread." if !parent.nil? && thread.nil?
    
    post = category.posts.create(:author => author, :title => sub, :body => txt, :parent_id => (thread.nil? ? nil : thread.id))
    
    return "> ".bold.red + post.errors.values.join(" ") unless post.valid?
    
    post.save
    online = R.lwho()
    notified = category.subscriptions.where(:user_id.in => online.split(' '))
    
    if (parent.nil?) then
      postnum = category.posts.where(:parent_id => nil).count
      notified.each do |i|
        R.nspemit(i.user.id, "(New BB message (#{category.num}/#{postnum}) posted to #{category.name} by #{R.penn_name(user.id)}: #{post.title})")
      end
      return "> ".bold.green + "You post your note about '#{sub}' in group #{category.num} (#{category.name}) as message ##{postnum}."
    else
      notified.each do |i|
        R.nspemit(i.user.id, "(New BB reply posted under message ##{parent} in group #{category.num} by #{R.penn_name(user.id)}: #{post.title})")
      end
      return "> ".bold.green + "You post your reply about '#{sub}' under message ##{parent} in group #{category.num} (#{category.name})."
    end
    
  end
  
  def self.draft_start(dbref, cat, sub, parent)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)
    subscription = user.subscriptions.where(:category_id => category.id).first
    
    return "> ".bold.red + "Either you do not subscribe to Group '#{cat}', or you are unable to post to it." unless !subscription.nil? && category.canwrite?(dbref)
    return "> ".bold.red + "You are already in the middle of writing a bbpost." unless user.draft.nil?
    
    thread = (parent.nil? ? nil : category.posts.where(:parent_id => nil)[parent.to_i - 1])
    return "> ".bold.red + "You can't post a reply to that thread." if !parent.nil? && thread.nil?
    
    draft = user.create_draft(:category_id => category.id, :title => sub, :parent_id => (thread.nil? ? nil : thread.id))
    
    return "> ".bold.red + draft.errors.values.join(" ") unless draft.valid?
    
    draft.save
    if (parent.nil?) then
      return "> ".bold.green + "You start your posting to Group ##{category.num} (#{category.name})."
    else 
      return "> ".bold.green + "You start your reply to message ##{parent} in group #{category.num} (#{category.name})."
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
    
    ret = post(user.id, category.name, user.draft.title, user.draft.body, thread.nil? ? nil : category.posts.find_index(thread) + 1)
    user.draft.destroy
    return ret  
  end
  
end
