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
end