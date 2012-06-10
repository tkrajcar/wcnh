module Items

  class Ammunition < Generic
    field :amount, type: Integer, default: 0
    field :caliber, type: String
  end

end