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
end
