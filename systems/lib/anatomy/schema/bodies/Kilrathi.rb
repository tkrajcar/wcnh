require 'wcnh'

module Anatomy
  
  class Kilrathi < Body
    
    @parts = {
      "Head" => [Anatomy::Head, {:mass => 9.0}],
      "Torso" => [Anatomy::Torso, {:mass => 24.0}],
      "Left Arm" => [Anatomy::Arm, {:mass => 9.5}],
      "Right Arm" => [Anatomy::Arm, {:mass => 9.5}],
      "Groin" => [Anatomy::Groin, {:mass => 5.5}],
      "Left Leg" => [Anatomy::Leg, {:mass => 14.0}],
      "Right Leg" => [Anatomy::Leg, {:mass => 14.0}],
      "Tail" => [Anatomy::Tail, {:mass => 2.0}]
      }
  end
  
end