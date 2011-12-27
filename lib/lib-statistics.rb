require 'wcnh'

module Statistics
  R = PennJSON::Remote

  def self.log(lwho)
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
    Log.create!(online_count: online_count, ic_count: ic_count, active_count: active_count)
    ""
  end

  class Log
    include Mongoid::Document
    field :timestamp, :type => DateTime, :default => lambda {DateTime.now }
    index :timestamp
    field :online_count, :type => Integer, :default => 0
    field :ic_count, :type => Integer, :default => 0
    field :active_count, :type => Integer, :default => 0
  end
end
