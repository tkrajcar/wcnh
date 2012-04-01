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

    category.update_attributes(opt.to_sym => val)
    return "> ".bold.red + category.errors[opt].join(" ") unless category.valid?

    category.save
    return "> ".bold.green + "'#{opt.capitalize}' option on board '#{category.name}' updated."
  end
   
end

