class String
  def to_bool
    return true if self == true || self =~ (/(true|1)$/i)
    return false if self == false || self.blank? || self =~ (/(false|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end