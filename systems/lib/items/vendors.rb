module Items

  def self.vendor_purchase(vendor, item, amount)
    amount = amount.to_i > 0 ? amount.to_i : 1
    enactor = R['enactor']
    wallet = Econ::Wallet.find_or_create_by(id: enactor)

    return "> ".bold.red + "Invalid vendor dbref.  Report this via +ticket." unless vendor = Vendor.where(dbref: vendor).first

    stock = vendor.items.where('attribs.lowercase_name' => item.downcase)
    return "> ".bold.red + "I don't see that item for sale." unless stock.count > 0
    available = stock.first.kind.stackable ? stock.first.attribs['amount'] : stock.count

    return "> ".bold.red + "Vendor has an invalid account.  Report this via +ticket." unless account = Econ::Account.where(_id: vendor.account).first
    return "> ".bold.red + "There are only #{available} of those available." unless available >= amount
    return "> ".bold.red + "You can only purchase one of those at a time." unless amount == 1 || stock.first.kind.stackable
  
    price = ((stock.first.attribs['value'] + (stock.first.attribs['value'] * vendor.markup)) * amount).to_i

    return "> ".bold.red + "You don't have enough credits." unless wallet.balance >= price

    if stock.first.kind.stackable && stock.first.attribs['amount'] > amount
      instance = Instance.where(dbref: create(vendor.dbref, stock.first.kind.number)).first
      instance_stock = Instance.where(_id: stock.first.id).first

      instance_stock.attribs['amount'] -= amount
      instance.attribs['amount'] += amount
      instance.save
      instance_stock.save
    else
      instance = stock.first
      instance.propagate
      vendor.items.delete(instance)
    end

    R.tel(instance.dbref, enactor)
    instance.rename
    group(enactor)
    wallet.balance -= price
    wallet.save
    account.deposit(R.penn_name(vendor.dbref), price)
    vendor.transactions.create!(customer: enactor, price: price)
    return "> ".bold.green + "You purchase #{amount} #{instance.attribs['name']} for #{price} credits."
  end

  def self.vendor_list(vendor)
    vendor = Vendor.where(dbref: vendor).first

    ret = titlebar("For Sale: #{R.penn_name(vendor.dbref)}") + "\n"
    ret << 'Item'.ljust(30).yellow + 'Type'.ljust(13).yellow + 'Price'.ljust(10).yellow + 'Amount'.yellow + "\n"

    vendor.inventory.each do |item|
      price = (item.attribs['value'] + (item.attribs['value'] * vendor.markup)).to_i
      list = vendor.items.where('attribs.name' => item.attribs['name'])

      ret << item.attribs['name'].ljust(30) + item.kind.class.name.partition('::').last.ljust(14)
      ret << "#{price}c".ljust(11)

      if item.kind.stackable
        ret << list.inject(0) { |tot, cur| cur.attribs['amount'] + tot }.to_s
      else
        ret << list.count.to_s
      end

      ret << "\n"
    end

    ret << "\n" + "Purchase <item> ".bold.yellow + 'to buy something.' + "\n"
    ret << "Purchase <item>=<amount> ".bold.yellow + 'to buy multiple things.' + "\n"
    ret << "Preview <item> ".bold.yellow + 'to preview an item.' + "\n"
    ret << footerbar
  end

  def self.vendor_stock(vendor, item, amount)
    amount = amount.to_i > 0 ? amount.to_i : 1
    vendor = Vendor.where(dbref: vendor).first

    return "> ".bold.red + "Invalid item number.  Check +item/list." unless item = Generic.where(number: item.to_i).first
    
    if item.stackable

      if (existing = vendor.items.where('attribs.name' => item.name).first)
        existing.attribs['amount'] += amount
        existing.save
      else
        vendor.items. << item.instances.create!
        vendor.items.last.attribs['amount'] = amount
        vendor.items.last.save
      end
      
    else
      amount.times { vendor.items. << item.instances.create! }
    end

    return "> ".bold.green + "#{amount} #{item.name} added to #{R.penn_name(vendor.dbref)}'s inventory."
  end

  def self.vendor_preview(vendor, item)
    return "> ".bold.red + "Invalid vendor dbref.  Report this via +ticket." unless vendor = Vendor.where(dbref: vendor).first
    
    stock = vendor.items.where('attribs.lowercase_name' => item.downcase)

    return "> ".bold.red + "There's nothing like that for sale." unless stock.count > 0

    available = stock.first.kind.stackable ? stock.first.attribs['amount'] : stock.count

    ret = titlebar(stock.first.attribs['name']) + "\n"
    ret << stock.first.show + "\n" "\n"
    ret << "#{R.penn_name(vendor.dbref)} has #{available.to_s.bold.yellow} of these available." + "\n"
    ret << footerbar
    return ret
  end

end