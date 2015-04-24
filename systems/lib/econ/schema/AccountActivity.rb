# individual activity on an account.
module Econ
  class AccountActivity
    include Mongoid::Document
    include Mongoid::Timestamps

    field :account, :type => String # ObjectId of account
    field :type, :type => String #types: 'deposit' 'withdraw' 'access_add' 'access_rem' 'owner_change' 'close' 'open'
    field :who, :type => String # Name of initiator. NOT A DBREF.
    field :amount, :type => BigDecimal, :default => BigDecimal.new("0") # for deposit/withdraw
    field :change, :type => String # change message for access_add/rem/owner_change
    field :balance, :type => BigDecimal, :default => BigDecimal.new("0") # balance after this Activity

    index :account
    index :type
  end
end
