require 'wcnh'

module Econ
  PennJSON::register_object(self)

  def self.pj_cash(person)
    self.cash(person)
  end

  def self.pj_pay(person,amount)
    self.pay(person,amount)
  end

  def self.pj_on_hand_balance(person)
    self.on_hand_balance(person)
  end

  def self.pj_grant(person,amount)
    self.grant(person,amount)
  end

#  def self.pj_putdown(amount)
#    self.putdown(amount)
#  end

  def self.pj_account_list(person)
    self.account_list(person)
  end

  def self.pj_account_deposit(account,amount)
    self.account_deposit(account,amount)
  end

  def self.pj_account_withdraw(account,amount)
    self.account_withdraw(account,amount)
  end

  def self.pj_account_view(account)
    self.account_view(account)
  end

  def self.pj_account_access(account,change)
    self.account_access(account,change)
  end

  def self.pj_account_owner(account,person)
    self.account_owner(account,person)
  end

  def self.pj_account_open(name)
    self.account_open(name)
  end

  def self.pj_account_close(name)
    self.account_close(name)
  end

  def self.pj_account_rename(account,newname)
    self.account_rename(account,newname)
  end
end

