module Items

  class Vendor
    include Mongoid::Document

    field :number, type: Integer, default: lambda { Counters.next('vendors') }
    index :vendor, unique: true
    field :dbref, type: String
    field :markup, type: Float, default: 0.25

    has_many :items, class_name: 'Items::Instance', inverse_of: :vendor
    has_many :transactions, class_name: 'Items::Transaction', inverse_of: :vendor
  end

end