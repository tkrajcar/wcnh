require 'wcnh'

module Anatomy
  
  class Body
    include Mongoid::Document
    
    field :dbref, type: String
    
    index :dbref, :unique => true
    
    embeds_many :parts, :class_name => "Anatomy::Part"
    
    after_create :assemble
    
    @@AUTOHEAL_MIN = 0
    @@AUTOHEAL_AMOUNT = 0.03
    class << self
      attr_accessor :parts
    end
    @parts = {}
    
    protected
    def assemble
      self.class.parts.each do |i, j|
        part = self.parts.create({name: i}, j[0])
        j[1..j.length].each do |k|
          part.update_attribute(k.keys.first, k[k.keys.first])
        end
      end
      self.save
    end
    
    public
    def getPctHealth
      total = 0
      self.parts.each { |i| total += i.pctHealth }
      return total / self.parts.count
    end
    
    def getMassTotal
      total = 0
      self.parts.each { |i| total += i.mass }
      return total
    end
    
    def applyDamage(force, target=nil)
      if (part = self.parts.find_index { |i| i.name == target }) then
        self.parts[part].applyDamage(force)
      elsif (!part && target) then
        return nil
      else
        self.parts[rand(self.parts.length - 1)].applyDamage(force)
      end
    end
    
    def doHeal
      self.parts.select { |i| i.pctHealth < 1.0 && i.pctHealth >= @@AUTOHEAL_MIN }.each do |j|
        j.pctHealth = [j.pctHealth + @@AUTOHEAL_AMOUNT, 1.0].min.round(2)
      end
      self.save
    end
  end
  
end
