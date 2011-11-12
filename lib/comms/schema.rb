require 'wcnh'

module Comms
  class Comlink
    # Generic IC comms object. Every IC player has a doc of this class, but there's nothing necessarily restricting it to players.
    include Mongoid::Document

    embeds_many :memberships, :class_name => "Comms::Membership"

    identity :type => String # use a MUSH dbref for id

    field :handles, :type => Array, :default => lambda { ["Anon" + Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by{rand}.join).upcase[0..6]]}
    field :lowercase_handles, :type => Array, :default => lambda { [self.handles.first.downcase] } # used to prevent two people from having same handle, different capitalizations
    field :active_handle, :type => String, :default => lambda { self.handles.first }
    field :dnd_on, :type => Boolean, :default => false

    index :handles, :unique => true
    index :active_handle
  end

  class Tightbeam
    include Mongoid::Document
    include Mongoid::Timestamps

    field :from, :type => String # id (which is a dbref) of sending Comlink
    field :from_handle, :type => String
    field :to_handles, :type => Array
    field :ic_timestamp, :type => DateTime, :default => lambda {DateTime.now} # TODO - needs to be IC time :)
    field :body, :type => String

    index :from
    index :to_handles
  end

  class Channel
    include Mongoid::Document

    identity :type => String # name of channel for id

    field :description, :type => String
    # TODO: Permissions stuff.
  end

  class Transmission
    include Mongoid::Document

    field :channel, :type => String #id (which is a string) of channel
    field :timestamp, :type => DateTime, :default => lambda {DateTime.now}
    field :ic_timestamp, :type => DateTime, :default => lambda {DateTime.now} # TODO - needs to be IC time :)
    field :from, :type => String # id (which is a dbref) of sending Comlink
    field :from_handle, :type => String
    field :text, :type => String

    index :channel
    index :from
    index :from_handle
  end

  class Membership
    include Mongoid::Document

    embedded_in :comlinks, :class_name => "Comms::Comlink"

    field :channel, :type => String
    field :active_handle, :type => String

    index :channel
  end
end