require 'wcnh'

module BBoard
  
  def self.post(author, cat, sub, txt)
    category = FindCategory(cat)
    
    return "> ".bold.red + "Either you do not subscribe to Group '#{cat}', or you are unable to post to it." if category.nil?
    
    post = category.posts.create(:author => author, :title => sub, :body => txt)
    
    return "> ".bold.red + post.errors.values.join(" ") unless post.valid?
    
    post.save
    return "> ".bold.green + "You post your note about '#{sub}' in group #{category.num} (#{category.name}) as message ##{category.posts.count}."
  end
  
  def self.draft_start(dbref, cat, sub)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)
    
    return "> ".bold.red + "Either you do not subscribe to Group '#{cat}', or you are unable to post to it." if category.nil?
    return "> ".bold.red + "You are already in the middle of writing a bbpost." unless user.draft.nil?
    
    draft = user.create_draft(:category_id => category.id, :title => sub)
    
    return "> ".bold.red + draft.errors.values.join(" ") unless draft.valid?
    
    draft.save
    return "> ".bold.green + "You start your posting to Group ##{category.num} (#{category.name})."
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
    
    ret = titlebar("BB Post in Progress") + "\n"
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
    
    ret = post(user.id, category.name, user.draft.title, user.draft.body)
    user.draft.destroy
    return ret  
  end
  
end
