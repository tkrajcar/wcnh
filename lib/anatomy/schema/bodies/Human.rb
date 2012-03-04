require 'wcnh'

module Anatomy
  
  class Human < Body
    
    @parts = {
      "Head" => [Anatomy::Head, {:mass => 6.0}],
      "Torso" => [Anatomy::Torso, {:mass => 21.0}],
      "LArm" => [Anatomy::Arm, {:mass => 6.5}],
      "RArm" => [Anatomy::Arm, {:mass => 6.5}],
      "Groin" => [Anatomy::Groin, {:mass => 2.5}],
      "LLeg" => [Anatomy::Leg, {:mass => 11.0}],
      "RLeg" => [Anatomy::Leg, {:mass => 11.0}]
      }
  end
  
end
