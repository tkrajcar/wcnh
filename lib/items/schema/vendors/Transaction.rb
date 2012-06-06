module Items

  class Transaction
    include Mongoid::Document
    include Mongoid::Timestamps::Created

    field :customer, type: String
    field :price, type: Integer

    belongs_to :vendor, class_name: "Items::Vendor", inverse_of: :transaction
    belongs_to :item, class_name: "Items::Instance", inverse_of: :transaction
  end

end