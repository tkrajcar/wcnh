require 'wcnh'

module Items
  
  def self.get_attr(dbref, attr)
    return '#-1 NO SUCH DOCUMENT' unless item = GenericItem.where(:dbref => dbref).first
    return '#-1 INVALID ATTRIBUTE' if item[attr.to_sym].nil?
    item.propagate
    return item[attr.to_sym].to_s
  end
  
end
