require 'wcnh'

module BBoard
  
  def self.category_create(cat)
    category = Category.create(:name => cat)
    return "> ".bold.red + category.errors[:name].join(" ") unless category.valid?
    category.save
    return "> ".bold.green + "New category '#{category.name}' created."
  end

  def self.category_config(cat, opt, val)
    category = FindCategory(cat)
    
    return "> ".bold.red + "No such category." if category.nil?
    
    options = category.fields.keys[2,category.fields.keys.length]
    return "> ".bold.red + "Invalid config option.  Valid options: " + options.itemize if options.find_index(opt).nil?
    
    val = nil if (val == "" || val == "none")
    category.update_attributes(opt.to_sym => val)
    return "> ".bold.red + category.errors[opt].join(" ") unless category.valid?

    category.save
    
    if (opt == 'permission_value' || opt == 'permission_type') then
      category.subscriptions.each do |i|
        i.destroy unless category.canread?(i.user.id)
      end
    end
    
    return "> ".bold.green + "'#{opt.capitalize}' option on board '#{category.name}' updated."
  end
  
  def self.sticky(dbref, cat, num, status)
    category = FindCategory(cat)
    user = User.find_or_create_by(:id => dbref)

    return "> ".bold.red + "You do not subscribe to that Group." unless !category.nil?
    
    post = category.posts.where(:parent_id => nil)[num.to_i - 1]
    
    return "> ".bold.red + "Message #{category.num}/#{num} (#{category.name}/#{num}) does not exist." if post.nil?
    
    if (post.sticky == false && status == false) then
      return "> ".bold.red + "That post is not sticky."
    elsif (post.sticky == true && status == true) then
      return "> ".bold.red + "That post is already sticky."
    end
    
    post.sticky = status
    post.save
    return "> ".bold.green + "Post #{num} on board #{category.num} (#{category.name}) is #{status == true ? 'now' : 'no longer'} sticky."
  end

  def self.timeout
    count = 0
    Category.all.each do |category|
      count += category.cleanup.to_i
    end
    Logs.log_syslog("BBOARD", "#{count} posts timed out and were archived.")
  end
   
end

