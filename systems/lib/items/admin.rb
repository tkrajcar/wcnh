require 'wcnh'

module Items
  
  def self.list(kind=nil)
    category = kind.to_s.downcase == 'generic' ? Generic : Generic.subclasses.find { |i| i.name =~ Regexp.new("(?i)#{kind}") }.desc(:number)
    
    return "> ".bold.red + "Invalid item type.  Check +item/list." if category.nil? && !kind.nil?
    
    if kind.nil? then
      ret = titlebar("Item Categories") + "\n"
      ret << "Generic (#{Generic.all.count} types, #{Instance.all.count} on grid)" + "\n"
      Generic.subclasses.each do |cat|
        total = 0
        cat.all.each { |i| total += i.instances.count }
        ret << '  ' * (cat.ancestors.count - Generic.ancestors.count)
        ret << cat.name.partition("::").last + " (#{cat.all.count} types, #{total} on grid)" + "\n"
      end
    else
      ret = titlebar("Items: #{category.name.partition("::").last}") + "\n"
      ret << "ID " "Name".ljust(30).cyan + "Type".ljust(10).cyan + "OnGrid".cyan + "\n"
      category.all.each do |item|
        ret << item.number.to_s.ljust(3) << item[:name].to_s.ljust(27) + item.class.name.partition("::").last.ljust(12) + item.instances.count.to_s + "\n"
      end
    end
   
   ret << footerbar
   ret
  end

  def self.edit(num, field, value)
    return "> ".bold.red + "No such item." unless item = Generic.where(number: num.to_i).first

    fields = item.fields.keys - EXCLUDE_FIELDS

    return "> ".bold.red + "Invalid field.  Valid fields: " + fields.itemize if fields.find_index(field).nil?
    item.update_attributes(field.to_sym => value)
    item.lowercase_name = value.to_s.downcase if field == 'name'
    return "> ".bold.red + item.errors[field].join(" ") unless item.valid?
    item.save

    item.instances.each do |instance|
      unless instance.customized
        instance.attribs[field] = item[field.to_sym]
        instance.rename if instance.dbref
        instance.save
      end
    end

    return "> ".bold.green + "'#{field.capitalize}' attribute on the parent #{item[:name]} updated."
  end

  def self.destroy(num)
    return "> ".bold.red + "No such item." unless item = Generic.where(number: num).first

    Logs.log_syslog('ITEM DESTROY', "#{R.penn_name(R['enactor'])} removed item no. #{item.number}, name: #{item[:name]}")
    item.destroy
    return "> ".bold.green + "Item no. #{item.number} destroyed."
  end

  def self.new(kind)
    item_class = kind == 'generic' ? Generic : Generic.subclasses.find { |i| i.name =~ Regexp.new("(?i)#{kind}") }

    return "> ".bold.red + "Invalid item type.  Check +item/list." if item_class.nil?
    item = item_class.create!

    Logs.log_syslog('ITEM NEW', "#{R.penn_name(R['enactor'])} added a new item parent, id: #{item.number}, class: #{item.class.name}")
    return "> ".bold.green + "Item no. #{item.number} created."
  end

  def self.view(num)
    return "> ".bold.red + "No such item." unless item = Generic.where(number: num).first

    exclude = EXCLUDE_FIELDS + %w[rounds amount] - ['stackable']
    fields = item.fields.keys - exclude
    
    ret = titlebar("Item #{item.number} - #{item.class.name} - #{item[:name]}") + "\n"
    fields.each do |field|
      ret << "#{field.upcase}: ".cyan + item[field.to_sym].to_s + "\n"
    end
    
    ret << footerbar

    ret
  end
  
  def self.fix(dbref)
    return "> ".bold.red + "Invalid item document." unless item = Instance.where(:dbref => dbref).first
    item.propagate
    item.rename
    item.save
    return "> ".bold.green + "Item #{item.dbref} has been fixed."
  end
  
end