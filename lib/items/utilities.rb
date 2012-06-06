require 'wcnh'

module Items
  MUSH_FUNCTIONS = '#1250'
  MUSH_PARENT = '#1256'
  
  def self.get_attr(dbref, attr)
    return '#-1 NO SUCH DOCUMENT' unless item = Instance.where(:dbref => dbref).first
    return '#-1 INVALID ATTRIBUTE' if item.attribs[attr].nil?
    return item.attribs[attr].to_s
  end

  def self.set_attr(dbref, attr, value)
    return '#-1 NO SUCH DOCUMENT' unless item = Instance.where(:dbref => dbref).first

    value.nil? ? item.attribs.delete[attr] : item.attribs[attr] = value
    item.save
    return "#{R.penn_name(item.dbref)}/#{attr.upcase} - #{value.nil? ? 'Cleared' : 'Set'}."
  end

  def self.create(type)
    return '#-1 INVALID ITEM TYPE' unless item = Generic.where(lowercase_name: type.downcase).first

    enactor = R["enactor"]
    item_mush = R.penn_u("#{MUSH_FUNCTIONS}/subfn.create",item.name)
    item_instance = item.instances.create!
    item_instance.dbref = item_mush
    item_instance.save
    item.propagate

    R.set(item_mush, "safe")
    R.penn_power(item_mush, "api")
    R.penn_parent(item_mush, MUSH_PARENT)
    R.tel(item_mush, enactor)
    Logs.log_syslog("ITEM CREATE", "#{R.penn_name(enactor)} instantiated #{item_mush}, type: #{item.name}, class: #{item.class.name}")
    return item_mush
  end
  
end
