require 'wcnh'

module Econ
  def self.account_list(person)
    victim = R.pmatch(person)
    return ">".bold.green + " Invalid target!" unless victim != "#-1"
    ret = titlebar("Bank Account List For #{R.penn_name(victim)}")
    accounts = Account.where(accessors: victim).where(open: true)
    ret << " #{"Name".ljust(15)} #{"Own?"} #{"Balance".rjust(18)} Last Activity\n".cyan
    accounts.each do |account|
      ret << account.id.ljust(16).bold
      if account.owner == victim
        ret << "Yes  ".bold.cyan
      else
        ret << "No   "
      end
      ret << credit_format(account.balance).rjust(18).bold.yellow
      ret << " "
      date = account.last_activity_date
      if date.nil?
        ret << "None Yet".cyan
      else
        ret << date.strftime("%m/%d/%y ").cyan
      end

      ret << "\n"
    end
    ret << footerbar()
  end

  def self.account_deposit(account, amount)
    a = Account.where(lowercase_name: account.downcase).first
    return ">".bold.green + " There's no account by that name." unless !a.nil?
    w = Wallet.find_or_create_by(id: R["enactor"])
    amount = BigDecimal.new(amount.delete(',')).round(1,:floor)
    return ">".bold.green + " You can't deposit negative money!" unless amount > 0
    return ">".bold.green + " That account is closed." unless a.open?
    return ">".bold.green + " You don't have enough credits to do that!" unless w.balance >= amount || R.orflags(R["enactor"],"Wr").to_bool
    a.deposit(R.penn_name(R["enactor"]), amount)
    w.balance = w.balance - amount
    w.save
    ">".bold.green + " You deposit #{credit_format(amount).bold.yellow} credits to account #{a._id.to_s.bold}."
  end

  def self.account_withdraw(account, amount)
    a = Account.where(lowercase_name: account.downcase).first
    return ">".bold.green + " There's no account by that name." unless !a.nil?
    w = Wallet.find_or_create_by(id: R["enactor"])
    amount = BigDecimal.new(amount.delete(',')).round(1,:floor)
    return ">".bold.green + " You can't withdraw negative money!" unless amount > 0
    return ">".bold.green + " That account is closed." unless a.open?
    return ">".bold.green + " Sorry, you don't have access to that account." unless a.accessors.include?(R["enactor"])
    return ">".bold.green + " That account does not have sufficient balance!" unless a.balance >= amount

    a.withdraw(R.penn_name(R["enactor"]), amount)
    w.balance = w.balance + amount
    w.save
    ">".bold.green + " You withdraw #{credit_format(amount).bold.yellow} credits from account #{a._id.to_s.bold}."
  end

  def self.account_view(account)
    a = Account.where(lowercase_name: account.downcase).first
    return ">".bold.green + " There's no account by that name." unless !a.nil?
    return ">".bold.green + " Sorry, you don't have access to that account." unless a.accessors.include?(R["enactor"]) || R.orflags(R["enactor"],"Wr").to_bool
    ret = titlebar("Account #{a._id} Details") + "\n"
    ret << "Owner:".ljust(15).cyan 
    ret << R.penn_name(a.owner).ljust(30).bold
    ret << "Balance:".ljust(15).cyan
    ret << credit_format(a.balance).bold.yellow
    ret << "\n"
    ret << "Access:".ljust(15).cyan
    accessor_names = []
    a.accessors.each do |accessor|
      accessor_names << R.penn_name(accessor).bold
    end
    ret << accessor_names.to_sentence
    ret << "\n"
    ret << middlebar("RECENT ACTIVITY") + "\n"
    ret << "#{"Date".ljust(14)} #{"By".ljust(20)} Type    Memo\n".cyan
    a.recent_activity.each do |activity|
      ret << activity.created_at.strftime("%m/%d/%y %H:%m ")
      ret << activity.who.ljust(21)
      case activity.type
      when "deposit"
        ret << "DEPOSIT ".bold + credit_format(activity.amount).bold.yellow + " credits."
      when "withdraw"
        ret << "WTHDRAW ".bold + credit_format(activity.amount).bold.yellow + " credits."
      when "access_add"
        ret << "ACC ADD ".bold + activity.change + " added."
      when "access_rem"
        ret << "ACC REM ".bold + activity.change + " removed."
      when "owner_change"
        ret << "OWNER   ".bold + "Owner changed to " + activity.change.bold.yellow + "."
      when "close"
        ret << "CLOSED  ".bold + "Account closed."
      when "open"
        ret << "OPENED  ".bold + "Account opened."
      else
        ret << activity.type
      end

      ret << "\n"
    end
    ret << footerbar
  end

  def self.account_access(account, change)
    a = Account.where(lowercase_name: account.downcase).first
    return ">".bold.green + " There's no account by that name." unless !a.nil?
    return ">".bold.green + " Only the owner may add or remove access." unless a.owner == R["enactor"] || R.orflags(R["enactor"],"Wr").to_bool
    return ">".bold.green + " That account is closed!" unless a.open?
    return ">".bold.green + " You must either + (add) or - (remove) someone from an account. For example, account/access foo=+Rince or account/access foo=-Paradox." unless change[0] == "-" || change[0] == "+"
    
    victim = R.pmatch(change[1..-1])
    return ">".bold.green + " Invalid target!" unless victim != "#-1"

    victim_name = R.penn_name(victim)
    enactor_name = R.penn_name(R["enactor"])

    if change[0] == "+"
      # adding someone
      return ">".bold.green + " #{victim_name.bold.yellow} already has access to account #{a._id.bold}!" unless !a.accessors.include?(victim)
      a.add_access(victim, enactor_name, victim_name)
      R.nspemit(victim,">".bold.green + " You have been granted access to bank account #{a._id.bold} by #{enactor_name.bold.yellow}.")
      return ">".bold.green + " Adding access for #{victim_name.bold.yellow} to account #{a._id.bold}."
    else
      # removing someone
      return ">".bold.green + " #{victim_name.bold.yellow} doesn't have access to account #{a._id.bold}!" unless a.accessors.include?(victim)
      return ">".bold.green + " You can't remove yourself, since you're the owner of the account! Use account/owner to switch owners first." unless a.owner != victim
      a.rem_access(victim, enactor_name, victim_name)
      R.nspemit(victim,">".bold.green + " Your access to bank account #{a._id.bold} has been removed by #{enactor_name.bold.yellow}.")
      return ">".bold.green + " Removing access for #{victim_name.bold.yellow} to account #{a._id.bold}."
    end
  end

  def self.account_owner(account,owner)
    a = Account.where(lowercase_name: account.downcase).first
    return ">".bold.green + " There's no account by that name." unless !a.nil?
    return ">".bold.green + " Only the owner may transfer an account to a new owner." unless a.owner == R["enactor"] || R.orflags(R["enactor"],"Wr").to_bool
    return ">".bold.green + " That account is closed!" unless a.open?
    victim = R.pmatch(owner)
    return ">".bold.green + " Invalid target!" unless victim != "#-1"

    victim_name = R.penn_name(victim)
    enactor_name = R.penn_name(R["enactor"])

    R.nspemit(victim, ">".bold.green + " #{enactor_name.bold.yellow} has transferred ownership of account #{a._id.bold} to you.")
    a.change_owner(victim, enactor_name, victim_name)
    return ">".bold.green + " You transfer ownership of account #{a._id.bold} to #{victim_name.bold.yellow}."
  end

  def self.account_open(account)
    return ">".bold.green + " Account names cannot be longer than 15 characters." unless account.length <= 15
    account_count = Account.where(owner: R["enactor"]).length
    return ">".bold.green + " You've opened 10 accounts already! Contact an admin if you need more for some reason." unless account_count <= 10 || R.orflags(R["enactor"],"Wr").to_bool
    return "> ".bold.green + "That account name is already in use." unless Account.where(lowercase_name: account.downcase).length == 0
    Account.open(account,R["enactor"],R.penn_name(R["enactor"]))
    return "> ".bold.green + " Account #{account.bold} opened."
  end

  def self.account_close(account)
    a = Account.where(lowercase_name: account.downcase).first
    return ">".bold.green + " There's no account by that name." unless !a.nil?
    return ">".bold.green + " Only the owner may close an account." unless a.owner == R["enactor"] || R.orflags(R["enactor"],"Wr").to_bool
    return ">".bold.green + " That account is already closed!" unless a.open?
    a.close(R["enactor"], R.penn_name(R["enactor"]))
    return ">".bold.green + " Account #{a._id.bold} has been closed."
  end
end
