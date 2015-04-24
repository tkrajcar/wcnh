class Array
  def random(weights=nil)
    return random(map {|n| n.send(weights)}) if weights.is_a? Symbol
  
    weights ||= Array.new(length, 1.0)
    total = weights.inject(0.0) {|t,w| t+w}
    point = rand * total
   
    zip(weights).each do |n,w|
      return n if w >= point
      point -= w
    end
  end
  
  def itemize
    return nil if self.length == 0
    return self.first.to_s if self.length == 1
    return "#{self.first} and #{self.last}" if self.length == 2
    return self[0,self.length - 1].join(", ") + ", and " + self.last.to_s
  end
  
  def to_mush
    self.to_s.gsub(/[\[\],"]/, '')
  end
end