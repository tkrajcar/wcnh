module Shiprace

  class Ticket
      include Mongoid::Document
      field :dbref, type: String
      field :wager, type: Integer
      belongs_to :racer, :class_name => "Shiprace::Racer"
  end

end