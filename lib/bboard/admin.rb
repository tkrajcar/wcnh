require 'wcnh'

module BBoard
  
  def self.category_create(cat)
    category = Category.create(:name => cat)
    return "> ".bold.red + category.errors[:name].to_mush unless category.valid?
    category.save
    return "> ".bold.green + "New category '#{category.name}' created."
  end
  
  def self.category_rename(cat, newname)
    return "> ".bold.red + "No such category." unless category = Category.where(:name => cat)
    category.name = newname
    return "> ".bold.red + category.errors[:name].to_mush unless category.valid?
    category.save
    return "> ".bold.green + "Category name changed to '#{category.name}'."
  end
  
end

