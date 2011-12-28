require 'wcnh'

module Logs
  PennJSON::register_object(self)

  def self.pj_log_rp(who,where,what)
    self.log_rp(who,where,what)
  end

  def self.pj_log_statistic(lwho)
    self.log_statistic(lwho)
  end
end
