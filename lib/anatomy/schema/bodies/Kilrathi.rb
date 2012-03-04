require 'wcnh'

module Anatomy
  
  class Kilrathi < Body
    
    @parts = {
      "Head" => [Anatomy::Head, {:mass => 9.0}],
      "Torso" => [Anatomy::Torso, {:mass => 24.0}],
      "LArm" => [Anatomy::Arm, {:mass => 9.5}],
      "RArm" => [Anatomy::Arm, {:mass => 9.5}],
      "Groin" => [Anatomy::Groin, {:mass => 5.5}],
      "LLeg" => [Anatomy::Leg, {:mass => 14.0}],
      "RLeg" => [Anatomy::Leg, {:mass => 14.0}],
      "Tail" => [Anatomy::Tail, {:mass => 2.0}]
      }
  end
  
end