# TODOs

This file details work being done, work to do next, and future ideas.

## Work Being Done

This is the list of work in-progress.

### Documentation

* Review and implement doc strategy via chargen

### Code

* Surveying planets for small amounts of credits

## Work To Do Next

This is the list of work that is next up to be tackled.

## Work In The Spec

This is the list of work needed to implement the spec.


## Idea Bucket

This is a spot to collect ideas for future work that is not in the spec.

## Completed

01-26-2011

* Create a README.md
* Move the spec into SPEC.md
* Remove WIZ from shuttle, console, airlock and ship parents, use API
* Move all airlock exit parent code into parent-airloc-exit.mush
* Write the canboard(console DBREF, player DBREF) space function
* Setup @lock/enter on the ship obj parent
* Move all ship thing parent code into parent-ship-thing.mush
* Move all command console parent code into parent-command-console.mush
* Move all shuttle kiosk parent code into parent-shuttle-kiosk.mush
* Add canuseconsole() function
* Add ismanned(), isunmanned(), ismanning() and mannedby() functions
* Add unman command
* Shift default function processing from console to ship
* Make all funcs process wiz/roy flag as default captain
* Update ISCREW to only pass on Captain or Crew, not Visitor
* Interior formatting.
* Launching, scanning landing
* Intra-system travel where time = Distance * Speed * Universal
* Set up system rooms and contents.
* Automated ship generation.
* Write roster/list, roster/add, and roster/remove
* Modify scan to take an arg.
* Comm command
* Add spose messages to land/launch.
* Tie piloting skill to ship speed.
* Tie jumping to astrogation skill. 
* Framework for dealing with parents/classes.
* Handle multi-room ship cloningi
* Deal with cloning consoles in multi-room ships.
* Set new airlock exits no_warn
* Set up airlock exit parent and add parenting to ship cloning.
* Intercom command
* Write admin help files.
* ETA command.
* Shuttles
* Spec out a few basic classes.
* Shipyards
* Selling a ship
* Bay commands

