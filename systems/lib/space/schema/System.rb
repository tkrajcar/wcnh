module Space
  class System
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, :type => String
    field :lowercase_name, :type => String, :default => lambda { self.name.downcase }
    
    has_many :locations, :class_name => "Econ::Location"
  end
end

