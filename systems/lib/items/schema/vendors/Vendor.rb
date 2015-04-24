module Items

  class Vendor
    include Mongoid::Document

    field :number, type: Integer, default: lambda { Counters.next('vendors') }
    index :number, unique: true
    field :dbref, type: String
    field :markup, type: Float, default: 0.25
    field :account, type: String # BSON ID of associated Econ::Account

    has_many :items, class_name: 'Items::Instance', inverse_of: :vendor
    has_many :transactions, class_name: 'Items::Transaction', inverse_of: :vendor

    def inventory
        list = self.items.map { |i| i.attribs['name'] }.uniq
        list.collect { |i| self.items.where('attribs.name' => i).first }
    end
  end

end