module Shiprace

  class Racer
      include Mongoid::Document
      field :name, type: String
      field :ship, type: String
      field :dbref, type: String
      field :skill, type: Integer, default: lambda { rand(6) + 1 }
      has_many :tickets, :class_name => "Shiprace::Ticket"

      def skillcheck
        rand(5) - 2 + self.skill
      end

      def weight(hash)
        return hash[self.skill]
      end
  end

end