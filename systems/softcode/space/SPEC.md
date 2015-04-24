# Overview

This document outlines the ideas for a stand-in space system for the Wing Commander: New Horizon MUSH. This system is temporary, and will be replaced by a more robust system in the future.

The guiding principle is simplicity that promotes role play and an interactive storytelling environment.

# Goals

* Give players a simple means to travel between systems/planets
* Give players their own ships on which to roleplays
* Give players an opportunity to roleplay in space
* Give players a reason to invest in space-related skill

# Definitions

**ship**: A player owned space ship. Players use ships to travel within a system, as well as betweel systems.

**shipyard**: A location where a player can purchase a ship from a shipyard vendor.

**station**: A space station is a stationary ship. It cannot travel.

**shuttle**: A ship that can be used by players who do not own their own ships. Players buy a ticket for a destination and the shuttle takes them there.

# Buying a Ship

Players will be able to purchase a ship from a shipyard. Shipyards can be found on planets or on stations. Upon purchase, a two hour timer will kick in to account for the time required to deliver the ship. This should serve as a deterrent to those that would mass purchase ships moments before a battle, as well as create time to complete anything computationally expensive during the ship building process.

After the two hours, the ship will be available to the player at the planet's landing field or in the station's docking bay.

# Boarding a Ship

Only those players listed on a ship's roster (see Securing a Ship) may board a ship. The player who purchases a ship is listed as Captain on the ship's roster. Disembarking from a ship is accomplished by exiting through an exit located in the ship's airlock.

Commands

	enter <ship>      Board a ship

# Securing a Ship

Players will be able to grant access to their ship to other players using the ship's Command Console. Other players can be assigned one of two roles: Visitor or Crew. Visitors are limited to boarding, disembarking, and using the intercom. Crew may additionally use the Command Console. Only the Captain of a ship may make changes to the roster.

Commands

	roster                          Display the different roster commands
	roster/list                     Display the current roster members
	roster/add <player>:<role>      Add a player to the roster
	roster/remove <player>          Remove a player from the roster

# Communicating in a Ship

Players can send a message throughout the ship using an intercom. Anyone on the ship can send a message. Intercoms are located in every room on the ship. The intercom message will be emit'd to each ship room.

Commands

	intercom <msg>       Send a message through the ship's intercom

# Piloting a Ship

Players will be able to plot a destination from the ship's Command Console. Destinations can be plotted while planetside or in orbit. A destination cannot be changed once the player engages the ship on its plotted route.

Commands

	plot                    Display the different plot commands
	plot/list               List destinations in the local system and the
                           names of other systems that have destinations
	plot/list <system>      List the destinations in a specific system
	plot/calc <code>        Plot a route to a destination. Travel time
                           will be influenced by the player's skill
                           in Astrogation and Piloting.

Example Output

Command: plot/list

	>--[Navigation: Available Destinations]--------------------------------------<
	
      LOCAL DESTINATIONS
       VS1: Vespus I          VS2: Vespus II          VS3: Asteroid Belt
       VS4: Asteroid Belt     VS5: Gas Giant          VS6: Gas Giant

      OTHER SYSTEMS
        CB: Cabrea             CD: Cardell             PB: Pembroke
        SP: Speardon

	 Use 'plot/calc <local code>' to plot a route to a local destination
	 Use 'plot/list <system code>' to view destinations in another system
	>--[Showing: plot/list]------------------------------------------------------<

Though it may appear complex at first glance, the idea behind using codes is that they are short and easily remembered, removing the need to issue a 'plot/list' every time.

# Being in Orbit

While in orbit, players can scan for other entities in space using the Command Console. Players can communicate with other ships. Players can pose their ships. Players can land their ships on planets or dock them with stations.

Commands

	scan                     List entities in orbit
	comm <entity> <msg>      Send a message to another entity
	spose <pose>             Display a pose to other entities in orbit
	land <planet>            Land on a planet
	dock <station|ship>      Dock with a station or carrier

# Planets & Space Stations

Space stations and planets also have Command Consoles. Their available commands, however, are limited to scan, comm, spose and roster.

# Carriers & Space Stations

Carriers have all the capabilities of other ships, but similar to stations, they can also be docked with. Players can open and close the docking bay doors of stations and carriers. There will be limits to the size of ships that can dock with carriers. Any size ship can dock with a space station (think links, for capital-size ships).

Commands

	bay             Display the open/closed status of the docking bay doors
	bay/open        Open the docking bay doors
	bay/close       Close the docking bay doors

# Shuttles

Shuttles can be used by players to travel between habitable planets and space stations. Shuttles will not allow players to travel to destinations such as asteroid belts, nebula, or non-habitable planets.

Commands

	shuttle                 Display the different shuttle commands
	shuttle/list            List destinations serviced by the shuttle
	shuttle/buy <code>      Purchase a ticket for a destination
	shuttle/board           Board the shuttle for your destination

# The Plumbing

When ships are launched, they will be @tel'd to a room that holds all objects currently in orbit of the planet/station the player launched from (a station's orbit is the same as the planet it orbits). The scan, comm and spose commands will use the list of objects in this room to determine their remit targets.

When ships engage a plotted route, they will be @tel'd to a jump room. No communication, scanning, etc can take place while in the middle of a jump. No, this doesn't fit entirely well with the instant-jumping between jump gates in WC canon. During the engaged route, we'll use remits throughout the ship to portray the bulk of the travel time as being due to navigation/travel to a jump gate. The jump through the gate will happen near the tail end of the ship's uninterruptible travel.

The ROOM ancestor will be used in combination with a room DBREF list (likely on the ship's Command Console) to avoid a flood of room parents.

Ship/station poses will be remit'd to the bridge rooms of ships/stations in orbit, not just the player manning the Control Console. It would be easy to also push these poses to observation decks
and other rooms.

Calculating the time required to travel between destinations is up in the air. Right now we're looking at a 2d X/Y coordinate grid.

	Vespus III: 38.45 10.02
	Vespus VI:  38.07 10.10
		
	Cardell II: 76.54 60.75
	Cardell VI: 76.22 59.85
		
Definitely open to suggestions...

Shuttles will be one of the faster modes of transit in the game. With a small playerbase, and a principal goal of facilitating RP, players shouldn't be keep out of RP because we decided to make travel times too damn realistic.
