module Items
  
  class Generic
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :number, :type => Integer, :default => lambda {Counters.next("items")}
    index :number, :unique => true
    field :name, type: String
    field :lowercase_name, type: String
    field :mass, type: Float, default: 0.0
    field :volume, type: Float, default: 0.0
    field :materials, type: Hash
    field :description, type: String, default: ''
    field :value, type: Integer, default: 0
    field :stackable, type: Boolean, default: false # If they can be grouped together like ammo
    
    has_many :instances, :class_name => "Items::Instance", inverse_of: :kind

    class << self
        attr_reader :showable # Hash of visible fields in the form of Key (sym) => String (suffix)
    end

    def self.subclasses
        ObjectSpace.each_object(Class).select { |klass| klass < self }.sort { |a, b| a.ancestors.count <=> b.ancestors.count }
    end
    
    def is_weapon
      return false
    end
  end
  
end
