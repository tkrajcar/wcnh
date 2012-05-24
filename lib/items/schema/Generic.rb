module Items
  
  class Generic
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :name, type: String
    field :lowercase_name, type: String
    field :mass, type: Float, default: 0.0
    field :volume, type: Float, default: 0.0
    field :materials, type: Hash
    field :description, type: String
    
    has_many :instances, :class_name => "Items::Instance", inverse_of: :kind
    
  end
  
end
