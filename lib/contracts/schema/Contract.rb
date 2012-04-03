# Individual contract.
module Contract
  class Contract
    include Mongoid::Document
    include Mongoid::Timestamps

    field :number, :type => Integer, :default => lambda {Counters.next("ticket")}
    index :number, :unique => true
    field :title, :type => String
    field :background, :type => String
    field :published, :type => Boolean, :default => false
    index :published
    field :close, :type => Date

    embeds_many :questions, :class_name => "Contract::Question"
    has_many :responses, :class_name => "Contract::Response"

  end

  class Question
    include Mongoid::Document
    embedded_in :contracts, :class_name => "Contract::Contract"

    field :number, :type => Integer
    field :text, :type => String
  end
end
