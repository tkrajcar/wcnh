require 'wcnh'

module Anatomy
  
  class Treatment
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :healer, type: String
    field :success, type: Integer
    field :part, type: String
    
    belongs_to :body, :class_name => "Anatomy::Body"
    
    @@TIMEOUT = 6.hours
    class << self
      attr_accessor :heal_range
    end
    @heal_range = 0..0
    
    def self.cleanup
      self.destroy_all(conditions: { :created_at.lt => DateTime.now - @@TIMEOUT })
    end
    
    def doTreat
      part = self.body.parts.find_index { |i| i.name == self.part }
      part = self.body.parts[part]
      if self.class.heal_range.include?(part.pctHealth) && self.success > 0 then
        part.pctHealth = [part.pctHealth + (self.success.round(2) / 100), 1.0].min
        part.save
        return part
      else return nil
      end
    end
  end
  
  class FirstAid < Treatment
    @heal_range = 0.4..0.8
  end
  
  class Medicine < Treatment
    @heal_range = 0.0..0.6
  end
end
