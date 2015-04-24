module Items

  class Instance
    include Mongoid::Document
    include Mongoid::Timestamps
    include Firearms
    
    field :dbref, type: String
    field :attribs, type: Hash, default: {}
    field :customized, type: Boolean, default: false
    
    belongs_to :kind, class_name: 'Items::Generic', inverse_of: :instances
    belongs_to :vendor, class_name: 'Items::Vendor', inverse_of: :items
    has_many :transactions, class_name: 'Items::Transaction', inverse_of: :item

    after_create :construct
    
    def is_weapon
      return self.kind.class.is_weapon
    end
    
    def is_gun
      return self.kind.class.is_gun
    end
    
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
        self.dbref = item_mush = R.penn_u("#{MUSH_FUNCTIONS}/subfn.create",self.kind[:name])
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

    def rename
      return "> ".bold.red + "Not propagated." unless self.dbref

      if self.kind.stackable
        name = self.kind.group_name(self.attribs['amount'], self.attribs['name'])
      else
        name = "#{self.attribs['name']} #{self.dbref.split('#').last}"
      end
      
      R.penn_name(self.dbref, name)
      return name
    end

    def show
      ret = self.attribs['description']
      return ret unless self.kind.class.showable
      
      ret << "\n"
      self.kind.class.showable.each do |field, suffix|
        ret << "\n" + "#{field.to_s.upcase.cyan}: #{self.attribs[field.to_s]} #{suffix}"
      end

      return ret
    end
  end
  
end
