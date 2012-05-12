class Float
  def to_timestring
    time = []
    hours = self.to_f / 3600
    time << "#{hours.to_i} hours" if hours.to_i > 0
    minutes = (hours - hours.to_i) * 60
    time << "#{minutes.to_i} minutes" if minutes.to_i > 0
    seconds = (minutes - minutes.to_i) * 60
    time << "#{seconds.to_i} seconds" if seconds.to_i > 0
    return time.join(', ')
  end
  
  def to_frac_odds
    base = (self - 1).round(1)
    div = 1
    
    until base % 1 == 0 do
      div += 1 
      base = (base * div).round(1)
    end
    
    result = (self * div).to_i
    
    if result % div == 0
      result = result / div
      div = div / div
    end
    
    return "#{result}:#{div}"
  end
end