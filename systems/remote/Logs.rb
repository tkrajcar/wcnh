require 'wcnh'

module Logs
  PennJSON::register_object(self)

  def self.pj_log_rp(who,where,what,was_emit=0)
    self.log_rp(who,where,what,was_emit)
  end

  def self.pj_roleplay_last(page=1)
    self.roleplay_last(page)
  end

  def self.pj_log_statistic(lwho)
    self.log_statistic(lwho)
  end

  def self.pj_log_syslog(category,message)
    self.log_syslog(category,message)
  end
end
