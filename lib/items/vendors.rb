module Items

  def self.vendor_purchase(vendor, item)
    enactor = R['enactor']
    wallet = Econ::Wallet.find_or_create_by(id: enactor)

    return "> ".bold.red + "Invalid vendor dbref.  Report this via +ticket." unless vendor = Vendor.where(dbref: vendor).first
    return "> ".bold.red + "Vendor has an invalid account.  Report this via +ticket." unless account = Econ::Account.where(_id: vendor.account).first
    return "> ".bold.red + "I don't see that item for sale." unless item = vendor.items.where('attribs.lowercase_name' => item.downcase).first
    return "> ".bold.red + "You don't have enough credits." unless wallet.balance >= (price = item.attribs['value'] + (item.attribs['value'] * vendor.markup))

    item.propagate
    vendor.items.delete(item)
    R.tel(item.dbref, enactor)
    wallet.balance -= price
    account.deposit(R.penn_name(vendor.dbref), price)
    vendor.transactions.create!(customer: enactor, price: price)
    return "> ".bold.green + "You purchase a #{item.attribs['name']} for #{price} credits."
  end

  def self.vendor_list(vendor)
    vendor = Vendor.where(dbref: vendor).first

    ret = titlebar("For Sale: #{R.penn_name(vendor.dbref)}") + "\n"
    ret << 'Item'.ljust(25).yellow + 'Type'.ljust(10).yellow + 'Price '.yellow + "\n"
    vendor.items.each do |item|
      price = (item.attribs['value'] + (item.attribs['value'] * vendor.markup)).to_i
      ret << item.attribs['name'].ljust(25) + item.kind.class.name.partition('::').last.ljust(10)
      ret << "#{price}c".ljust(10) + "\n"
    end
    ret << "\n" + "Purchase <item> ".bold.yellow + 'to buy something.' + "\n"
    ret << footerbar
  end

  def self.vendor_stock(vendor, item)
    vendor = Vendor.where(dbref: vendor).first

    return "> ".bold.red + "Invalid item number.  Check +item/list." unless item = Generic.where(number: item).first
    
    vendor.items << item.instances.create!
    return "> ".bold.green + "#{item.name} added to #{R.penn_name(vendor.dbref)}'s inventory."
  end

end