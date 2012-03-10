require 'wcnh'

module Anatomy
  
  class Treatment
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :healer, type: String
    field :success, type: Integer
    
    embeds_one :region, :class_name => "Anatomy::Part"
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
      if self.class.heal_range.include?(self.region.pctHealth) && self.success > 0 then
        self.region.pctHealth = [self.region.pctHealth + self.success.round(1) / 100, 1.0].min.round(2)
        self.region.save
        return self.region
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
