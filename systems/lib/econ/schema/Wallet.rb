# Wallet object. Every IC player has a doc of this class, but there's nothing necessarily restricting it to players.
module Econ
  class Wallet
    include Mongoid::Document
    include Mongoid::Timestamps

    identity :type => String # use a MUSH dbref for id
    field :balance, :type => BigDecimal, :default => BigDecimal.new("0")
  end
end
