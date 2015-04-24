module Shiprace
  
  class Race
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :order, type: Array, default: []
    field :completed, type: Boolean, default: false
    
    has_and_belongs_to_many :racers, :class_name => "Shiprace::Racer"
    has_many :tickets, :class_name => 'Shiprace::Ticket'
    
    def balance
      return self.tickets.map { |ticket| ticket.wager }.inject(0) { |total, wager| total += wager }
    end
    
    def balance_by_racer(racer)
      return nil unless self.racers.include?(racer)
      return self.tickets.where(racer_id: racer.id).inject(0) { |total, ticket| total += ticket.wager }
    end
    
    def odds(racer)
      return nil unless self.racers.include?(racer)
      
      spent_total = self.balance * (1.0 - RACE_TAKE)
      spent_racer = [self.balance_by_racer(racer), 1.0].max
      
      unless spent_total > 0
        return 1 + rand.round(1) if racer.skill < 4
        return 1.0
      end
      
      prob = ((spent_total - spent_racer).to_f / spent_racer.to_f).round(1)
      
      return 1.0 if prob < 0
      return [prob, 10.0].min
    end
  end
  
end