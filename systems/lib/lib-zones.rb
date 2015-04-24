require 'wcnh'

module Zones
  def self.checkout(bc, dbref)
    checkout = Checkout.create!(bc: bc, dbref: dbref)
    return
  end

  def self.history(bc)
    history = Checkout.where(bc: bc)
    return "> ".red + "No records found." unless history.length > 0
    ret = titlebar("History for #{R.penn_name(bc)}") + "\n"
    ret << " User".ljust(20).yellow + "Checked Out".yellow  + "\n"
    history.each do |i|
      ret << " #{R.penn_name(i.dbref).ljust(20)} #{i.time.strftime("%m/%d/%y %H:%M")}\n"
    end
    ret << footerbar
    ret
  end

  class Checkout
    include Mongoid::Document
    field :bc, type: String
    index :bc
    field :dbref, type: String
    field :time, type: Time, default: lambda {DateTime.now}
  end
end
