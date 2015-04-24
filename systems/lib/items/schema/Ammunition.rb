module Items

  class Ammunition < Generic
    field :name, type: String
    field :multiplier, type: Float, default: 1.0
    field :amount, type: Integer, default: 0
    field :energy, type: Boolean, default: false

    after_initialize do |document|
      self.stackable = true
    end

    def group_name(amount, name)
      singular = self[:energy] ? 'charge' : 'round'
      plural = self[:energy] ? 'charges' : 'rounds'
      return "#{amount} #{amount > 1 ? plural : singular} of #{self[:name]}"
    end
  end

end