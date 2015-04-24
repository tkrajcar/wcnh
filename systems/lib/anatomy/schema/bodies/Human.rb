require 'wcnh'

module Anatomy
  
  class Human < Body
    
    @parts = {
      "Head" => [Anatomy::Head, {:mass => 6.0}],
      "Torso" => [Anatomy::Torso, {:mass => 21.0}],
      "Left Arm" => [Anatomy::Arm, {:mass => 6.5}],
      "Right Arm" => [Anatomy::Arm, {:mass => 6.5}],
      "Groin" => [Anatomy::Groin, {:mass => 2.5}],
      "Left Leg" => [Anatomy::Leg, {:mass => 11.0}],
      "Right Leg" => [Anatomy::Leg, {:mass => 11.0}]
      }
  end
  
end
