require 'wcnh'

module Anatomy
  
  class Kilrathi < Body
    
    @@parts = {
      "Head" => Anatomy::Head,
      "Torso" => Anatomy::Torso,
      "LArm" => Anatomy::Arm,
      "RArm" => Anatomy::Arm,
      "Groin" => Anatomy::Groin,
      "LLeg" => Anatomy::Leg,
      "RLeg" => Anatomy::Leg,
      "Tail" => Anatomy::Tail
      }
  end
  
end