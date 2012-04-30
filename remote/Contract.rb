require 'wcnh'

module Contract
  PennJSON::register_object(self)

  def self.pj_list
    self.list
  end

  def self.pj_view(contract)
    self.view(contract)
  end

  def self.pj_response(contract)
    self.response(contract)
  end

  def self.pj_answer(job,question,answer)
    self.answer(job,question,answer)
  end

  def self.pj_submit(job)
    self.submit(job)
  end

  def self.pj_create_new
    self.create_new
  end

  def self.pj_set_date(year,month,day)
    self.set_date(year,month,day)
  end

  def self.pj_set_title(title)
    self.set_title(title)
  end

  def self.pj_set_background(background)
    self.set_background(background)
  end

  def self.pj_set_question(question,answer)
    self.set_question(question,answer)
  end

  def self.pj_publish
    self.publish
  end

  def self.pj_award(contract,firm)
    self.award(contract,firm)
  end

  def self.pj_responses(contract)
    self.responses(contract)
  end
  
  def self.pj_response_view(contract,response)
    self.response_view(contract,response)
  end

  def self.pj_reminder
    self.reminder
  end
end
