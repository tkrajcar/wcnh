class DateTime
  def to_ictime
    icsecs = (self.to_i - 1320000000) * 3
    return DateTime.strptime(icsecs.to_s, '%s') + 760.years
  end
end