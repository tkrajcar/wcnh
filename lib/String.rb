class String
  def to_bool
    return true if self == true || self =~ (/(true|1)$/i)
    return false if self == false || self.blank? || self =~ (/(false|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end

  def trim_and_ljust_with_ansi(trim_to_length)
    ansi_character_length = self.length - self.remove_penn_ansi.length
    self[0,trim_to_length + ansi_character_length].ljust(trim_to_length + ansi_character_length + 1)
  end
end