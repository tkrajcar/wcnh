require 'wcnh'

module Items
  
  def self.list(kind=nil)
    category = kind == "all" ? Generic : Generic.subclasses.find { |i| i.name =~ Regexp.new("(?i)#{kind}") }
    
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
      ret << "Name".ljust(20).cyan + "Type".ljust(10).cyan + "OnGrid".cyan + "\n"
      category.all.each do |item|
        ret << item.name.ljust(20) + item.class.name.partition("::").last.ljust(12) + item.instances.count.to_s + "\n"
      end
    end
   
   ret << footerbar
   ret
    
  end  
  
end