require 'wcnh'

module Anatomy
  
  class Part
    include Mongoid::Document
    
    field :mass, type: Float, :default => 0
    field :pctHealth, type: Float, :default => 1.0
    field :name, type: String, :default => lambda { self.name.split(":").last }
    
    embedded_in :body, :class_name => "Anatomy::Body"
    
    def getPctMassOfBody
      self.mass / self.body.getMassTotal
    end
    
    def applyDamage(force)
      damage = (0.012 / self.mass) * force
      self.pctHealth = [self.pctHealth - damage, 0].max.round(2)
      self.save
      return self
    end
  end
  
end
