# Payments are recorded whenever an on-hand payment is made
module Econ
  class Payment
    include Mongoid::Document
    include Mongoid::Timestamps
    field :from, :type => String # id (which is a dbref) of sending Wallet
    field :to, :type => String # id (which is a dbref) of receiving Wallet, or "dropped" if result of 'put down'.
    field :amount, :type => BigDecimal

    index :from
    index :to
  end
end
