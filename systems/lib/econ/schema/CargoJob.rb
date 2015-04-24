module Econ
  class CargoJob
    BASE_CARGO_RATE_MIN = 25.0
    BASE_CARGO_RATE_MAX = 35.0
    TIME_FACTOR_MULTIPLIER = [0,0.8,1.0,1.5,2.0,3.0]
    GRADE_MULTIPLIER = [0,0.6,0.8,1.0,1.2,1.4,2.0]
    GRADE_WORDS = ['', 'surplus', 'low-grade', 'unremarkable', 'fine', 'exquisite']
    TIME_FACTOR_INTERVALS = [0, 36.0..48.0, 24.0..36.0, 9.0..24.0, 3.0..9.0, 1.5..3.0]

    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :commodity, :class_name => "Econ::Commodity"
    field :number, :type => Integer, :default => lambda {Counters.next("cargojob")}

    field :grade, :type => Integer, :default => 3
    field :expires, :type => DateTime
    field :claimed, :type => Boolean
    field :claimed_by, :type => String #dbref of claimant
    field :assigned_to, :type => String
    field :completed, :type => Boolean, :default => false
    field :is_loaded, :type => Boolean, :default => false
    field :loaded_on, :type => String #dbref of ship job is loaded on
    field :delivered, :type => Boolean, :default => false
    field :customer, :type => String
    field :size, :type => Integer
    field :price, :type => Integer
    field :visibility, :type => Integer
    field :publicity, :type => String
    belongs_to :source, :class_name => "Econ::Location"
    belongs_to :destination, :class_name => "Econ::Location"

    index :number, :unique => true
    index :source
    index :destination
    index :commodity
    index :completed
    index :claimed
    index :visibility
    index :assigned_to

    scope :open_and_claimed_by, ->(person) { where(claimed_by: person).where(:expires.gt => DateTime.now).where(completed:false).asc(:expires) }
    scope :unloaded_and_claimed_by, ->(person) { where(claimed_by: person).where(:expires.gt => DateTime.now).where(completed:false).where(is_loaded:false).asc(:expires) }
    scope :unloaded_and_assigned_to, ->(person) { where(assigned_to: person).where(:expires.gt => DateTime.now).where(completed:false).where(is_loaded:false).asc(:expires) }
    scope :loaded_and_claimed_by, ->(person) { where(claimed_by: person).where(completed:false).where(is_loaded:true).asc(:expires) }
    scope :loaded_and_assigned_to, ->(person) { where(assigned_to: person).where(completed:false).where(is_loaded:true).asc(:expires) }
    
    validates_numericality_of :grade, greater_than: 0, less_than: 6, only_integer: true, message: "Grade must be an integer >0 and <6."
    validates_numericality_of :size, greater_than: 0, only_integer: true, message: "Size must be a positive integer."
    validates_numericality_of :price, greater_than_or_equal_to: 0, only_integer: true, message: "Price must be an integer >=0."
    validates_numericality_of :visibility, greater_than_or_equal_to: 0, only_integer: true, message: "Visibility must be an integer >=0."

    def grade_text
      GRADE_WORDS[self.grade]
    end

    def to_mush
      number_string = self.number.to_s.rjust(5)
      self.publicity.nil? ? ret = number_string.bold : ret = number_string.bold.red
      ret << " "
      ret << "#{self.source.name}-#{self.destination.name}".ljust(22)
      ret << self.size.to_s.rjust(4)
      ret << Econ.credit_format(self.price).to_s.rjust(8).bold.yellow
      ret << " "
      expires_in = self.expires.to_time - DateTime.now
      if expires_in > 0
        mm, ss = expires_in.divmod(60)
        hh, mm = mm.divmod(60)
        dd, hh = hh.divmod(24)
        if dd > 0
          ret << "#{dd}d "
        else
          ret << "   "
        end
        ret << "#{hh.to_s.rjust(2,'0')}:#{mm.to_s.rjust(2,'0')}"
      else
        ret << " EXPIRED".bold.red
      end
      ret << " "
      ret << self.grade_text
      ret << " "
      ret << self.commodity.name[0..15]
      ret << "\n"
    end

    def self.generate
      commodity = Econ::Commodity.all.to_a.shuffle.pop
      p "Commodity: #{commodity.name}"

      from_picklist = []
      commodity.demand_factors.where(:factor.gte => -1).each do |from_system|
        from_picklist << {location: from_system.location, weighted_factor: rand(1.0..1.5) ** (1 + (from_system.factor + 2) / 5)}
      end
      from_picklist.sort! {|x,y| x[:weighted_factor] <=> y[:weighted_factor]}
      from = from_picklist.pop
      p "From: #{from[:location].name} (system #{from[:location].system._id})"

      to_picklist = []
      to_list = commodity.demand_factors.where(:factor.lte => 1).where(:location_id.ne => from[:location]._id)
      if to_list.count == 0
        p "Couldn't find a destination system. Aborting."
        return
      end
      to_list.each do |to_system|
        to_picklist << {location: to_system.location, weighted_factor: rand(1.0..1.5) ** (1 + ((to_system.factor * -1) + 2) / 5)}
      end
      to_picklist.sort! {|x,y| x[:weighted_factor] <=> y[:weighted_factor]}
      to = to_picklist.pop
      p "To: #{to[:location].name} (system #{to[:location].system._id})"

      grade = [1,1,2,2,3,3,4,5].shuffle[0]
      p "Grade: #{grade}"

      time_factor = [1,1,1,2,2,3,3,4,5].shuffle[0]
      p "Time factor: #{time_factor}"

      size = [rand(3..15),rand(10..30),rand(15..50),rand(50..100),rand(100..200)].shuffle[0]
      p "Size: #{size}"

      distance_1 = Econ::Distance.where(system_a_id: from[:location].system._id).where(system_b_id: to[:location].system._id)
      distance_2 = Econ::Distance.where(system_a_id: to[:location].system._id).where(system_b_id: from[:location].system._id)
      if(distance_1.count > 0)
        distance = distance_1.first.distance
      elsif(distance_2.count > 0)
        distance = distance_2.first.distance
      else
        distance = 1
        p "ERROR: No distance found!!"
      end
      p "Distance: #{distance}"


      visibility = (1 + grade + time_factor + rand(-1..1)) / 2
      p "Visibility: #{visibility}"

      price = rand(BASE_CARGO_RATE_MIN..BASE_CARGO_RATE_MAX) * (size ** 0.75) * TIME_FACTOR_MULTIPLIER[time_factor] * GRADE_MULTIPLIER[grade] * (distance ** 0.7)
      price = price * R.default("#19/CARGO_PRICE_MULTIPLIER","1.0").to_f
      p "Price: #{price}. Price per unit: #{price / size}"

      expires = DateTime.now + rand(TIME_FACTOR_INTERVALS[time_factor]).hours

      CargoJob.create!(commodity: commodity, expires: expires, grade: grade, claimed: false, completed: false, size: size, price: price.to_i, source: from[:location], destination: to[:location], visibility: visibility)
    end
  end
end

