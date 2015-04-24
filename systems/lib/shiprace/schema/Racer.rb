module Shiprace

  class Racer
      include Mongoid::Document
      field :name, type: String
      field :ship, type: String
      field :dbref, type: String
      field :skill, type: Integer, default: lambda { rand(6) + 1 }
      
      has_and_belongs_to_many :races, :class_name => "Shiprace::Race"
      has_many :tickets, :class_name => "Shiprace::Ticket"
      has_one :ship, :class_name => "Shiprace::Ship"

      def skillcheck
        rand(5) - 2 + self.skill
      end

      def weight(hash)
        return hash[self.skill]
      end
  end

end