require 'wcnh'

module Econ
  # helper function
  def self.credit_format(number) # return formatted (1,234.56) number
    number.round(1,:floor).to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
  end

  # Wallet object. Every IC player has a doc of this class, but there's nothing necessarily restricting it to players.
  class Wallet
    include Mongoid::Document
    include Mongoid::Timestamps

    identity :type => String # use a MUSH dbref for id
    field :balance, :type => BigDecimal, :default => BigDecimal.new(0)
  end

  # Payments are recorded whenever an on-hand payment is made
  class Payment
    include Mongoid::Document
    include Mongoid::Timestamps
    field :from, :type => String # id (which is a dbref) of sending Wallet
    field :to, :type => String # id (which is a dbref) of receiving Wallet, or "dropped" if result of 'put down'.
    field :amount, :type => BigDecimal

    index :from
    index :to
  end

  # Bank account.
  class Account
    include Mongoid::Document
    include Mongoid::Timestamps

    identity :type => String # name of account for id (normal case)
    field :lowercase_name, :type => String, :default => lambda { self._id.downcase }
    field :owner, :type => String # owner dbref
    field :accessors, :type => Array # array of dbrefs that can access
    field :balance, :type => BigDecimal, :default => BigDecimal.new(0)

    index :lowercase_name
    index :accessors
  end

  # individual transmission on a channel, numeric or named.
  class AccountActivity
    include Mongoid::Document
    include Mongoid::Timestamps

    field :account, :type => String #id (which is a string) of account
    field :type, :type => String #types: 'deposit' 'withdraw' 'access_add' 'access_rem' 'owner_change'
    field :who, :type => String # id (which is a dbref) of initiator
    field :amount, :type => BigDecimal, :default => BigDecimal.new(0) # for deposit/withdraw
    field :change, :type => String # change message for access_add/rem/owner_change
    field :balance, :type => BigDecimal, :default => BigDecimal.new(0) # balance after this Activity

    index :account
    index :type
  end
end
