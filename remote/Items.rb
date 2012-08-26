require 'wcnh'

module Items
  PennJSON::register_object(self)
  R = PennJSON::Remote
  
  def self.pj_attr_get(dbref, attr)
    self.attr_get(dbref, attr)
  end
  
  def self.pj_list(kind=nil)
    self.list(kind)
  end

  def self.pj_create(dbref, type)
    self.create(dbref, type)
  end

  def self.pj_attr_set(dbref, attr, value=nil)
    self.attr_set(dbref, attr, value)
  end

  def self.pj_edit(num, field, value=nil)
    self.edit(num, field, value)
  end

  def self.pj_destroy(num)
    self.destroy(num)
  end

  def self.pj_new(kind)
    self.new(kind)
  end

  def self.pj_view(num)
    self.view(num)
  end

  def self.pj_vendor_purchase(vendor, item, amount)
    self.vendor_purchase(vendor, item, amount)
  end

  def self.pj_vendor_list(vendor)
    self.vendor_list(vendor)
  end

  def self.pj_vendor_stock(vendor, item, amount)
    self.vendor_stock(vendor, item, amount)
  end

  def self.pj_remove(enactor, dbref)
    self.remove(enactor, dbref)
  end

  def self.pj_group(location)
    self.group(location)
  end

  def self.pj_vendor_preview(vendor, item)
    self.vendor_preview(vendor, item)
  end
  
  def self.pj_fix(dbref)
    self.fix(dbref)
  end

end