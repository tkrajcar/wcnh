require 'wcnh'

module Econ
  R = PennJSON::Remote

  def self.cash(person)
    w = Wallet.find_or_create_by(id: R["enactor"])
    return ">".bold.green + " You have #{credit_format(w.balance).bold.yellow} credits on-hand."
  end

  def self.pay(person,amount)
    sender_wallet = Wallet.find_or_create_by(id: R["enactor"])
    victim = R.pmatch(person)
    return ">".bold.green + " Invalid payee!" unless victim != "#-1"
    victim_wallet = Wallet.find_or_create_by(id: victim)
    return ">".bold.green + " You can only pay people in the same room as you!" unless R.loc(R["enactor"]) == R.loc(victim) || R.orflags(R["enactor"],"Wr").to_bool
    amount = BigDecimal.new(amount.delete(',')).round(1,:floor)
    return ">".bold.green + " You don't have enough credits to do that!" unless sender_wallet.balance >= amount || R.orflags(R["enactor"],"Wr").to_bool
    sender_name = R.penn_name(R["enactor"])
    victim_name = R.penn_name(victim)
    Logs.log_syslog("ECONPAY","#{sender_name} paid #{victim_name} #{amount} credits.")
    R.nspemit(victim,">".bold.green + " #{sender_name.bold} pays you #{credit_format(amount).bold.yellow} credits.")
    victim_wallet.balance = victim_wallet.balance + amount
    victim_wallet.save
    sender_wallet.balance = sender_wallet.balance - amount
    sender_wallet.save
    ">".bold.green + " You pay #{victim_name.bold} #{credit_format(amount).bold.yellow} credits."
  end

  def self.putdown(amount)
    "Not implemented"
  end
end
