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
    ret << 'Item'.ljust(25).yellow + 'Type'.ljust(13).yellow + 'Price'.ljust(10).yellow + 'Amount'.yellow + "\n"

    vendor.inventory.each do |item|
      price = (item.attribs['value'] + (item.attribs['value'] * vendor.markup)).to_i
      list = vendor.items.where('attribs.name' => item.attribs['name'])

      ret << item.attribs['name'].ljust(25) + item.kind.class.name.partition('::').last.ljust(14)
      ret << "#{price}c".ljust(11)

      if item.kind.class == Items::Ammunition
        ret << list.inject(0) { |tot, cur| cur.attribs['amount'] + tot }.to_s
      else
        ret << list.count.to_s
      end

      ret << "\n"
    end

    ret << "\n" + "Purchase <item> ".bold.yellow + 'to buy something.' + "\n"
    ret << footerbar
  end

  def self.vendor_stock(vendor, item)
    vendor = Vendor.where(dbref: vendor).first

    return "> ".bold.red + "Invalid item number.  Check +item/list." unless item = Generic.where(number: item.to_i).first
    
    if (item.class == Items::Ammunition)

      if (existing = vendor.items.where('attribs.name' => item.name).first)
        existing.attribs['amount'] += 100
        existing.save
      else
        vendor.items. << item.instances.create!
        vendor.items.last.attribs['amount'] = 100
        vendor.items.last.save
      end
      
    else
      vendor.items. << item.instances.create!
    end

    return "> ".bold.green + "#{item.name} added to #{R.penn_name(vendor.dbref)}'s inventory."
  end

end