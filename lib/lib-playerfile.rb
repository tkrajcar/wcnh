require 'wcnh'

module PlayerFile
  R = PennJSON::Remote

  def self.register_email(dbref, email)
    p = Player.create(:email => email)

    Player.all_of(:email => email).count.to_s
  end

  def self.find_email(email)
    Player.all_of(:email => email).first.inspect

  end

  class Player
    include Mongoid::Document
    field :email, :type => String
    index :email, :unique => true
  end
end
