require 'wcnh'

module BBoard
  
  def self.index(cat)
    if (cat.to_i > 0) then
      category = Category.all.to_a[cat.to_i - 1]
    else
      category = Category.where(:name => cat).first
    end
    
    return "> ".bold.red + "No such category." if category.nil?
    
    index = Category.all.to_a.find_index(category) + 1
    
    ret = titlebar(category.name) + "\n"
    ret << "        Message".yellow.ljust(27) + "Posted        By".yellow + "\n"
    ret << footerbar + "\n"
    
    category.posts.each_index do |i|
      post = category.posts[i]
      ret << "#{index}/#{i + 1}".ljust(8) + post.title.ljust(27) + post.created_at.strftime("%a %b %d").ljust(14) + post.author
    end
    ret << footerbar
    
    return ret
  end
  
end
