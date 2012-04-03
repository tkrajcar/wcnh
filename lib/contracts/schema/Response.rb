# Contract response.
module Contract
  class Response
    include Mongoid::Document
    include Mongoid::Timestamps

    field :submitted, :type => Boolean, :default => false
    field :author, :type => String

    belongs_to :contract, :class_name => "Contract::Contract"

    embeds_many :answers, :class_name => "Contract::Answer"

  end

  class Answer
    include Mongoid::Document
    embedded_in :responses, :class_name => "Contract::Response"

    field :number, :type => Integer
    field :text, :type => String
  end
end

