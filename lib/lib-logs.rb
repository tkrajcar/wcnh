require 'wcnh'

module Logs
  R = PennJSON::Remote

  def self.log_rp(who,where,what,was_emit=0)
    who_name = R.penn_name(who)
    where_name = R.penn_name(where)
    where_zone = R.zone(where)
    where_zone_name = R.penn_name(where_zone)
    players_present = R.filter("#LAMBDA/HASFLAG(\%0,CONNECTED)",R.lplayers(where)).split(' ')
    Roleplay.create!(who: who,
                    who_name: who_name, 
                    where: where, 
                    where_name: where_name,
                    where_zone: where_zone,
                    where_zone_name: where_zone_name,
                    what: what, 
                    players_present: players_present)
    cemit = "[#{where_name}-#{where}]".green
    cemit += " <#{who_name}>" if was_emit.to_bool
    cemit += " #{what}"
    R.nscemit("+RP",cemit,"1")
    ""
  end

  def self.log_statistic(lwho)
    online = lwho.split(' ')
    online_count = online.count
    ic_count = 0
    active_count = 0
    online.each do |person|
      if R.hasflag(person,"IC") == "1"
        ic_count += 1
      end
      if R.idlesecs(person).to_i < 3600
        active_count += 1
      end
    end
    Statistic.create!(online_count: online_count, ic_count: ic_count, active_count: active_count)
    ""
  end

  def self.log_syslog(category,message)
    Syslog.create!(category: category, enactor: R["enactor"], caller: R["caller"], message: message)
    R.cemit("syslog","[".bold.blue + "SysLog".bold.white + "] ".bold.blue + "#{category}: ".bold.white + message)
  end

  class Statistic
    include Mongoid::Document
    field :timestamp, :type => DateTime, :default => lambda {DateTime.now }
    index :timestamp
    field :online_count, :type => Integer, :default => 0
    field :ic_count, :type => Integer, :default => 0
    field :active_count, :type => Integer, :default => 0
  end

  class Roleplay
    include Mongoid::Document
    field :timestamp, :type => DateTime, :default => lambda {DateTime.now }
    index :timestamp
    field :who, :type => String
    index :who
    field :who_name, :type => String
    field :where, :type => String
    index :where
    field :where_name, :type => String
    field :where_zone, :type => String
    index :where_zone
    field :where_zone_name, :type => String
    field :what, :type => String
    field :players_present, :type => Array
    index :players_present
  end

  class Syslog
    include Mongoid::Document
    field :timestamp, :type => DateTime, :default => lambda {DateTime.now }
    index :timestamp 
    field :category, :type => String
    index :category
    field :enactor, :type => String
    index :enactor
    field :caller, :type => String
    index :caller
    field :message, :type => String
  end
end
