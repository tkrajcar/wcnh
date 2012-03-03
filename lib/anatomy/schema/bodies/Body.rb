require 'wcnh'

module Anatomy
  
  class Body
    include Mongoid::Document
    
    field :dbref, type: String
    
    index :dbref, :unique => true
    
    embeds_many :parts, :class_name => "Anatomy::Part"
    
    after_initialize :assemble
    
    class << self
      attr_accessor :parts
    end
    @parts = {}
    
    protected
    def assemble
      self.class.parts.each do |i, j|
        self.parts.create({name: i}, j)
      end
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
  end
  
end
