module Items

  class Instance
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :dbref, type: String
    field :attribs, type: Hash, default: {}
    
    belongs_to :kind, :class_name => "Items::Generic", inverse_of: :instances

    after_create :construct
    
    def construct
      exclude = [:created_at, :updated_at]
      
      self.kind.fields.keys.select{ |i| /^_.*/ !~ i && !exclude.include?(i.to_sym) }.each do |field|
        self.attribs[field.to_sym] = self.kind[field.to_sym]
      end
      self.save
      return self.attribs.count
    end

    def propagate
      R.set(self.dbref, "id:#{self._id}") unless self.dbref.nil?
      return
    end
  end
  
end
