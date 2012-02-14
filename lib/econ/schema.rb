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
    field :balance, :type => BigDecimal, :default => BigDecimal.new("0")
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

    field :name, :type => String
    field :lowercase_name, :type => String, :default => lambda { self.name.downcase }
    field :owner, :type => String # owner dbref
    field :accessors, :type => Array, :default => lambda { [self.owner] } # array of dbrefs that can access
    field :balance, :type => BigDecimal, :default => BigDecimal.new("0")
    field :open, :type => Boolean, :default => true

    index :lowercase_name, :unique => true
    index :accessors

    def last_activity_date
      activity = AccountActivity.where(account: self.id).order_by([:created_at, :desc]).first
      return nil unless !activity.nil?
      return activity.created_at
    end

    def recent_activity
      AccountActivity.where(account:self.id).order_by([:created_at, :desc]).limit(20)
    end

    def deposit(by_who, amount)
      self.balance = self.balance + amount
      self.save
      self.log_activity("deposit",by_who,amount,"")
    end

    def withdraw(by_who, amount)
      self.balance = self.balance - amount
      self.save
      self.log_activity("withdraw",by_who,amount,"")
    end

    def add_access(who, by_who, who_name)
      self.accessors << who
      self.save
      self.log_activity("access_add",by_who,0,who_name)
    end

    def rem_access(who, by_who, who_name)
      self.accessors.delete(who)
      self.save
      self.log_activity("access_rem",by_who,0,who_name)
    end

    def change_owner(who, by_who, who_name)
      self.owner = who
      self.accessors << who unless self.accessors.include?(who)
      self.save
      self.log_activity("owner_change",by_who,0,who_name)
    end

    def close(enactor, enactor_name)
      self.open = false
      self.save
      self.log_activity("close",enactor_name,0,"")
    end

    def self.open(name, enactor, enactor_name)
      a = Account.create!(name: name, owner: enactor)
      a.log_activity("open",enactor_name,0,"")
    end

    def rename(newname, enactor, enactor_name)
      self.name = newname
      self.lowercase_name = newname.downcase
      self.save
      self.log_activity("rename",enactor_name,0,newname)
    end

    def log_activity(type,who,amount,change_msg)
      Logs.log_syslog("BANK#{type.upcase}","#{who} #{type} to account #{self._id} (#{self.name}). #{change_msg} #{amount} - balance: #{self.balance}")
      AccountActivity.create!(account: self._id, type: type, who: who, amount: amount, change: change_msg, balance: self.balance)
    end
  end

  # individual activity on an account.
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
