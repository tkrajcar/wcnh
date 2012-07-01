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

  def self.pj_account_deposit(dbref,account,amount)
    self.account_deposit(dbref,account,amount)
  end

  def self.pj_account_withdraw(dbref,account,amount)
    self.account_withdraw(dbref,account,amount)
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

  def self.pj_cargojob_list
    self.cargojob_list
  end

  def self.pj_cargojob_claim(job)
    self.cargojob_claim(job)
  end

  def self.pj_cargojob_unclaim(job)
    self.cargojob_unclaim(job)
  end

  def self.pj_cargojob_load(job,shipname)
    self.cargojob_load(job,shipname)
  end

  def self.pj_cargojob_deliver(job)
    self.cargojob_deliver(job)
  end

  def self.pj_cargojob_assign(job,shipname)
    self.cargojob_assign(job,shipname)
  end

  def self.pj_cargojob_unassign(job)
    self.cargojob_unassign(job)
  end

  def self.pj_cargojob_generate(user=nil)
    self.cargojob_generate(user)
  end

  def self.pj_cargojob_manifest(ship)
    self.cargojob_manifest(ship)
  end

  def self.pj_cargojob_transfer(job,to_ship)
    self.cargojob_transfer(job,to_ship)
  end

  def self.pj_location_distance(a,b)
    Econ::Distance.find_distance(a,b).to_s
  end
  
  def self.pj_cargojob_edit(user, num, opt, val)
    self.cargojob_edit(user, num, opt, val)
  end

  def self.pj_admin_report
    self.admin_report
  end
end

