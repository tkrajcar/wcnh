module Items
  
  class GenericItem
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :uppercase_name, type: String
    field :lowercase_name, type: String
    field :mass, type: Float, default: 0.0
    field :volume, type: Float, default: 0.0
    field :dbref, type: String, default: nil
    field :materials, type: Hash
    
    def propagate
      R.set(self.dbref, "id:#{self._id}") unless self.dbref.nil?
      return
    end
  end
  
end