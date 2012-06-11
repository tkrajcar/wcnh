require 'wcnh'

module Items
  MUSH_FUNCTIONS = '#1250'
  MUSH_PARENT = '#1256'
  EXCLUDE_FIELDS = %w[materials lowercase_name _type _id created_at updated_at number stackable amount] # Fields that shouldn't be viewable/editable via +item 
  GARBAGE_ROOM = '#1266'
  
  def self.attr_get(dbref, attr)
    return '#-1 NO SUCH DOCUMENT' unless item = Instance.where(:dbref => dbref).first
    return '#-1 INVALID ATTRIBUTE' if item.attribs[attr].nil?
    return item.attribs[attr].to_s
  end

  def self.attr_set(dbref, attr, value)
    return '#-1 NO SUCH DOCUMENT' unless item = Instance.where(:dbref => dbref).first

    value.nil? ? item.attribs.delete[attr] : item.attribs[attr] = value
    item.save
    return "#{R.penn_name(item.dbref)}/#{attr.upcase} - #{value.nil? ? 'Cleared' : 'Set'}."
  end

  def self.create(enactor, type)
    return "> ".bold.red + "Invalid item ID." unless item = Generic.where(number: type.to_i).first

    instance = item.instances.create!
    item_mush = instance.propagate

    R.tel(item_mush, enactor)
    Logs.log_syslog("ITEM CREATE", "#{R.penn_name(enactor)} instantiated #{item_mush}, type: #{item.name}, class: #{item.class.name}")
    return item_mush
  end

  def self.remove(enactor, dbref)
    return "> ".bold.red + "Unable to locate that item in the database." unless instance = Instance.where(dbref: dbref).first
    instance.transactions.destroy_all
    R.set(dbref, "!safe halt")
    R.powers(dbref, "!api")
    R.tel(dbref, GARBAGE_ROOM)
    instance.destroy
    Logs.log_syslog("ITEM REMOVE", "#{R.penn_name(enactor)} removed #{instance.dbref}, type: #{instance.kind.name}")
    return "> ".bold.red + "Item #{instance.dbref} removed from the db."
  end
  
end
