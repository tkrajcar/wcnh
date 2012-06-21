# Individual contract.
module Contract
  class Contract
    include Mongoid::Document
    include Mongoid::Timestamps

    field :number, :type => Integer, :default => lambda {Counters.next("contract")}
    index :number, :unique => true
    field :title, :type => String, :default => ""
    field :background, :type => String, :default => ""
    field :published, :type => Boolean, :default => false
    index :published
    field :close, :type => Date, :default => lambda {7.days.from_now}
    field :awarded_to, :type => String, :default => ""

    embeds_many :questions, :class_name => "Contract::Question"
    has_many :responses, :class_name => "Contract::Response"

    def close_string
      if self.close.nil?
        return "Unset".bold.yellow
      elsif DateTime.now.to_date > self.close
        return "Closed on #{self.close.strftime('%m/%d/%y')}".bold.red
      else
        return self.close.strftime("%m/%d/%y").bold.cyan
      end
    end
  end

  class Question
    include Mongoid::Document
    embedded_in :contracts, :class_name => "Contract::Contract"

    field :number, :type => Integer
    field :text, :type => String
  end
end
