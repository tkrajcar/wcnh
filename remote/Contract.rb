require 'wcnh'

module Contract
  PennJSON::register_object(self)

  def self.pj_list
    self.list
  end

  def self.pj_respond(job)
    self.respond(job)
  end

  def self.pj_answer(job,question,answer)
    self.answer(job,question,answer)
  end

  def self.pj_submit(job)
    self.submit(job)
  end

  def self.pj_new
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
end
