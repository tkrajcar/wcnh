module Items

  class Instance
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :dbref, type: String
    field :attribs, type: Hash, default: {}
    
    belongs_to :kind, class_name: 'Items::Generic', inverse_of: :instances
    belongs_to :vendor, class_name: 'Items::Vendor', inverse_of: :items
    has_many :transactions, class_name: 'Items::Transaction', inverse_of: :item

    after_create :construct
    
    def construct
      exclude = [:created_at, :updated_at, :number]
      
      self.kind.fields.keys.select{ |i| /^_.*/ !~ i && !exclude.include?(i.to_sym) }.each do |field|
        self.attribs[field.to_sym] = self.kind[field.to_sym]
      end
      self.save
      return self.attribs.count
    end

    def propagate
      if self.dbref.nil?
        self.dbref = item_mush = R.penn_u("#{MUSH_FUNCTIONS}/subfn.create",self.kind.name)
        self.save
      else
        item_mush = self.dbref
      end

      R.set(item_mush, "safe")
      R.penn_powers(item_mush, "api")
      R.penn_parent(item_mush, MUSH_PARENT)
      R.set(item_mush, "id:#{self._id}")
      return item_mush
    end
  end
  
end
