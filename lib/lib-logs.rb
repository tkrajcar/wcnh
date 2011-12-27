require 'wcnh'

module Logs
  R = PennJSON::Remote

  def self.log_rp(who,where,what)
    who_name = R.penn_name(who)
    where_name = R.penn_name(where)
    where_zone = R.zone(where)
    where_zone_name = R.penn_name(where_zone)
    Roleplay.create!(who: who,
                    who_name: who_name, 
                    where: where, 
                    where_name: where_name,
                    where_zone: where_zone,
                    where_zone_name: where_zone_name,
                    what: what)
    ""
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
  end
end
