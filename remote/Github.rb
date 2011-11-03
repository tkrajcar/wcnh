require 'wcnh'

module Github
  PennJSON::register_object(self)
  R = PennJSON::Remote

  def self.pj_issues_list(*args)
    self.issues_list
  end
end


