require 'wcnh'

module Contract
  R = PennJSON::Remote

  def self.list
    ret = titlebar("Enigma Sector Procurement: Open & Recently Closed Contracts") + "\n"
    ret << "  #### #{'Title'.ljust(50)} Closes".cyan + "\n"
    criteria = Contract.where(:close.gt => 1.week.ago)
    criteria = criteria.where(published: true) unless R.orflags(R["enactor"],"Wr").to_bool
    criteria.desc(:close).each do |contract|
      ret << "  #{contract.number.to_s.rjust(4).bold.yellow} #{contract.title.ljust(50).bold} #{contract.close_string} #{contract.published ? "" : "UNPUBLISHED".bold.red}\n"
    end
    ret << "\n  Use #{'contract <number>'.bold} to view details of an individual contract.\n"
    ret << footerbar
    return ret
  end

  def self.view(contract)
    c = Contract.where(number: contract)
    return "> ".bold + "That isn't a valid contract number." if c.count == 0
    c = c.first
    return "> ".bold + "That isn't a valid contract number." unless c.published || R.orflags(R["enactor"],"Wr").to_bool
    ret = titlebar("Enigma Sector Procurement: Contract #{c.number}") + "\n"
    ret << middlebar("BACKGROUND") + "\n"
    ret << c.background
    ret << "\n"
    ret << middlebar("QUESTIONS TO BE ANSWERED BY RESPONDENTS") + "\n"
    c.questions.asc(:number).each do |q|
      ret << "#{q.number.to_s.bold}: #{q.text}\n"
    end
    ret << middlebar("STATUS") + "\n"
    if c.close > DateTime.now.to_date
      ret << "Qualified individuals and organizations are encouraged to submit bids on this contract by its closing date of #{c.close.strftime('%m/%d/%y').bold}.\n"
    else
      ret << "This contract has been closed; no new responses are accepted.\n"
    end
    ret << footerbar
  end

  def self.create_new
    c = Contract.new
    c.save
    Logs::log_syslog("CONTRACTNEW","#{R.penn_name(R["enactor"])} created new contract #{c.number}.")
    R.attrib_set("#{R["enactor"]}/CHAR`CONTRACT", c.number.to_s)
    return "> ".bold  + "New contract #{c.number.to_s.bold} created."
  end

  def self.set_title(title)
    c = Contract.where(number: R.xget(R["enactor"],"CHAR`CONTRACT")).first
    c.title = title
    c.save
    return "> ".bold + "Set contract #{c.number} title to #{title}."
  end

  def self.set_background(background)
    c = Contract.where(number: R.xget(R["enactor"],"CHAR`CONTRACT")).first
    c.background = background
    c.save
    return "> ".bold + "Set contract #{c.number} background to #{background}."
  end

  def self.set_date(year,month,day)
    c = Contract.where(number: R.xget(R["enactor"],"CHAR`CONTRACT")).first
    c.close = Date.new(year.to_i,month.to_i,day.to_i)
    c.save
    return "> ".bold + "Set contract #{c.number} date to #{c.close.strftime('%m/%d/%y')}."
  end

  def self.set_question(question,text)
    c = Contract.where(number: R.xget(R["enactor"],"CHAR`CONTRACT")).first
    q = c.questions.find_or_create_by(number: question.to_i)
    q.text = text
    q.save
    q.delete if text == ""
    c.save
    return "> ".bold + "Set contract #{c.number} question #{question} to #{text}."
  end

  def self.publish
    c = Contract.where(number: R.xget(R["enactor"],"CHAR`CONTRACT")).first
    return "> ".bold + "This contract has already been published!" if c.published
    c.published = true
    c.save
    R.u("#65/fn.contract_publish",c.number.to_s,c.title,c.close.strftime('%m/%d/%y'))
    return "> ".bold + "Contract #{c.number} published. +bbpost will occur automatically."
  end

  def self.response(contract)
    c = Contract.where(number: contract)
    return "> ".bold + "That isn't a valid contract number." if c.count == 0
    c = c.first
    return "> ".bold + "That isn't a valid contract number." unless c.published || R.orflags(R["enactor"],"Wr").to_bool
    r = Response.where(author: R["enactor"], contract_id: c._id)
    return "> ".bold + "You have not started a response to that contract yet! Use contract/answer first." unless r = r.first
    ret = titlebar("Enigma Sector Procurement: Your Response To Contract #{c.number}") + "\n"
    c.questions.asc(:number).each do |q|
      ret << "#{q.number.to_s.bold}: #{q.text.cyan}\n"
      a = r.answers.where(number: q.number).first
      ret << (a.nil? ? "Not Yet Answered".bold.red : a.text) + "\n"
    end
      ret << (r.submitted ? "This response has been submitted and can no longer be changed.".bold : "You have not yet submitted this response.".bold.yellow) + "\n"
    ret << footerbar
  end

  def self.answer(contract,question,answer)
    c = Contract.where(number: contract)
    return "> ".bold + "That isn't a valid contract number." if c.count == 0
    c = c.first
    return "> ".bold + "That contract has not been published." unless c.published
    return "> ".bold + "That contract is no longer open to new bids." unless DateTime.now.to_date < c.close
    r = Response.find_or_create_by(author: R["enactor"], contract_id: c._id)
    return "> ".bold + "You've already submitted your response to that contract!" if r.submitted
    q = c.questions.where(number: question.to_i).first
    a = r.answers.find_or_create_by(number: question.to_i)
    a.text = answer
    a.save
    a.delete if answer == ""
    r.save
    return "> ".bold + "Set answer to question #{question} on contract #{c.number} to #{answer}."
  end

  def self.submit(contract)
    c = Contract.where(number: contract)
    return "> ".bold + "That isn't a valid contract number." if c.count == 0
    c = c.first
    return "> ".bold + "That contract has not been published." unless c.published
    return "> ".bold + "That contract is no longer open to new bids." unless DateTime.now.to_date < c.close
    r = Response.find_or_create_by(author: R["enactor"], contract_id: c._id)
    return "> ".bold + "You've already submitted your response to that contract!" if r.submitted

    r.submitted = true
    r.save
    Logs::log_syslog("CONTRACTNEW","#{R.penn_name(R["enactor"])} submitted a response to contract #{c.number}.")
    return "> ".bold + "You submit your response for contract #{c.number}."
  end

  def self.award(contract,firm)
    c = Contract.where(number: contract)
    return "> ".bold + "That isn't a valid contract number." if c.count == 0
    c = c.first
    return "> ".bold + "That contract has not been published." unless c.published
    return "> ".bold + "That contract has not closed yet." unless DateTime.now.to_date > c.close
    return "> ".bold + "That contract has already been awarded." unless c.awarded_to = ""
    c.awarded_to = firm
    c.save

    R.u("#65/fn.contract_award",c.number.to_s,c.title,firm)
    return "> ".bold + "You award contract #{c.number} to #{firm}. +bbpost will happen automatically."
  end

  def self.responses(contract)
    c = Contract.where(number: contract)
    return "> ".bold + "That isn't a valid contract number." if c.count == 0
    c = c.first
    return "> ".bold + "That contract has not been published." unless c.published
    ret = titlebar("Enigma Sector Procurement: Responses to Contract #{c.number}") + "\n"

    c.responses.where(submitted: true).each do |response|
      ret << "#{response.author.rjust(6).bold} Submitted by #{R.penn_name(response.author)}\n"
    end
    ret << footerbar()
  end

  def self.response_view(contract,response)
    c = Contract.where(number: contract)
    return "> ".bold + "That isn't a valid contract number." if c.count == 0
    c = c.first
    return "> ".bold + "That contract has not been published." unless c.published
    r = Response.where(author: response, contract_id: c._id)
    return "> ".bold + "Cannot find that response." unless r = r.first
    ret = titlebar("Enigma Sector Procurement: #{R.penn_name(r.author)}'s Response To Contract #{c.number}") + "\n"
    c.questions.asc(:number).each do |q|
      ret << "#{q.number.to_s.bold}: #{q.text.cyan}\n"
      a = r.answers.where(number: q.number).first
      ret << (a.nil? ? "Not Yet Answered".bold.red : a.text) + "\n"
    end
    ret << footerbar
  end

  def self.reminder
    list = Contract.where(:published => true, :close.lt => DateTime.now.to_date + 24.hours, :close.gt => DateTime.now.to_date)
    return if list.count < 1
    list_array = []
    list.each { |i| list_array << i.number }
    return list_array.to_mush
  end
end
