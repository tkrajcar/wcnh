require 'wcnh'

module Items
  MUSH_FUNCTIONS = '#1250'
  MUSH_PARENT = '#1256'
  EXCLUDE_FIELDS = %w[materials lowercase_name _type _id created_at updated_at number stackable amount] # Fields that shouldn't be viewable/editable via +item 
  GARBAGE_ROOM = '#1266'
  
  def self.attr_get(dbref, attr)
    return '#-1 NO SUCH DOCUMENT' unless item = Instance.where(:dbref => dbref).first
    return item.show if attr == 'show'
    return (item.kind.is_weapon ? '1' : '0') if attr == 'is_weapon'
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
    Logs.log_syslog("ITEM CREATE", "#{R.penn_name(enactor)} instantiated #{item_mush}, type: #{item[:name]}, class: #{item.class.name}")
    return item_mush
  end

  def self.remove(enactor, dbref)
    return "> ".bold.red + "Unable to locate that item in the database." unless instance = Instance.where(dbref: dbref).first
    instance.transactions.destroy_all
    R.set(dbref, "!safe halt")
    R.powers(dbref, "!api")
    R.tel(dbref, GARBAGE_ROOM)
    instance.destroy
    Logs.log_syslog("ITEM REMOVE", "#{R.penn_name(enactor)} removed #{instance.dbref}, type: #{instance.kind.attributes['name']}")
    return "> ".bold.red + "Item #{instance.dbref} removed from the db."
  end

  def self.group(location)
    groupable = []
    removed = 0

    R.lthings(location).split(' ').each do |item|
      if exists = Instance.where(dbref: item).first
        groupable << exists if exists.kind.stackable
      end
    end

    return "> ".bold.red + "No groupable items in that location." unless groupable.length > 1

    groupable.map { |i| i.attribs['name'] }.uniq.each do |i| # An array of unique groupable item names
      items = groupable.select { |j| j.attribs['name'] == i } # All of the items for this particular group
      next if items.length < 2
      total = items.inject(0) { |k, l| k += l.attribs['amount'] } # How many are there total
      final = items.pop # The item that will be left after grouping
      final.attribs['amount'] = total
      final.save
      final.rename
      removed += items.length
      items.each { |j| remove(MUSH_FUNCTIONS, j.dbref) }
    end
    return "> ".bold.green + "#{removed} items removed and grouped."
  end
  
end
