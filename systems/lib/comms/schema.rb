require 'wcnh'

module Comms
  # Generic IC comms object. Every IC player has a doc of this class, but there's nothing necessarily restricting it to players.
  class Comlink
    include Mongoid::Document

    embeds_many :memberships, :class_name => "Comms::Membership"

    identity :type => String # use a MUSH dbref for id

    # to prevent two people from having same handle, different capitalizations, we store :lowercase_handles, which is maintained
    # as a copy of :handles with everything downcased, basically. the app layer takes care of this. eventually it would be nice
    # to do it at the db layer.
    field :handles, :type => Array, :default => lambda { ["Anon" + Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by{rand}.join).upcase[0..6]]}
    field :lowercase_handles, :type => Array, :default => lambda { [self.handles.first.downcase] }
    field :active_handle, :type => String, :default => lambda { self.handles.first }
    #field :dnd_on, :type => Boolean, :default => false
    field :unread_tightbeams, :type => Array, :default => []

    index :lowercase_handles, :unique => true # no need to index :handles at present as there are no commands that search it!
    index :active_handle
  end

  # individual tightbeam message
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

  # named channel. numeric-based channels do not have their own documents as they have no metadata associated.
  class Channel
    include Mongoid::Document

    identity :type => String # name of channel for id
    field :lowercase_name, :type => String, :default => lambda { self._id.downcase }
    field :description, :type => String
    field :permission_type, :type => String # used for permission handling - see can_join below. Use 'nil' for no permissions.
    field :permission_value, :type => String

    index :lowercase_name

    def can_see?(dbref)
      return true if R.orflags(dbref,"Wr").to_bool # roy/wiz always can join
      return true if self.permission_type.nil? # no permissions set
      if self.permission_type == "faction"
        members = R.u("#114/fn.list.members",self.permission_value) || ""
        return members.split(' ').include?(dbref)
      end
      return false # failsafe in case a bad permission_type is set
    end
  end

  # individual transmission on a channel, numeric or named.
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

  # record of a comlink's membership in a channel.
  class Membership
    include Mongoid::Document

    embedded_in :comlinks, :class_name => "Comms::Comlink"

    field :channel, :type => String
    field :active_handle, :type => String
    field :shortcut, :type => String # we use 'alias' in the UI but it's a reserved word, soooo...

    index :channel
  end
end
