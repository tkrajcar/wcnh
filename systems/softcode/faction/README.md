# Faction System for Wing Commander: New Horizon

Our faction system is designed to be modular and adaptable in a game world
where the political dynamics and inter-faction relationships are constantly
changing.  

## History

As a human on RH, you had practically no contact with the Kilrathi on a daily
basis, and that includes OOCly (unless you had friends you talked to). The two
sides were unable to communicate. There was no convenient way to arrange RP,
and that was fine. The lines of conflict were clearly drawn in the sand. There
was all-out war. And when you have 30+ people online nightly, you don't need to
worry about isolating players in their own little faction-world without access
to RP and communication with other players. That won't work for us - at least
not in the early stages of the game - for reasons I've already mentioned. Our
system needs to be fluid and adaptable because our game politics are in a
constant state of change. Additionally, we want players to be able to chat,
arrange RP, and all that jazz. 

## Tiers

The system is designed around the idea of faction tiers.  The highest faction
tiers represent large groups of people with complicated and varying goals and
agendas.  The lowest level is (usually) a small group with very specific
motivations.  Factions can be "owned" by other factions.  For example, several
military factions representing the different branches of the military (marines,
navy, etc.) may all belong to a single government entity (Confed).  Larger
corporations can own smaller corporations, etc.. In the first example, Confed
would appear at the top of the faction tree on +fac/list with the various
military branches beneath it.  This relationship may have some sort of system
significance in the future.  There are no limitations on faction ownership
except that a faction can only belong to a single other faction.  However, one
faction can own any number of sub-factions.  

### Tier 1: Government

At the highest level, everyone is at least loosely associated with a government entity
of some sort. They may have very minimal contact with that government, but they
are still a citizen of some sort. On RH, this would be your TC, UBW, and EK.
System support for faction leaders at this level will potentially include the
ability to do things like change tax rates.  Members may be heavily involved in
the daily operations of the government (politicians, government officials), or
they may have almost no involvement beyond the fact that they were born in a
particular place.  Governments get a faction channel and bboard by default.

### Tier 2: Military

Self-explanatory.  Organized military forces only.  Does not include pirates or
gangs.  Probably does not include private military forces (Blackwater), but
that is debateable for now.  All militaries probably belong to a government
faction of some sort.

### Tier 3: Corporation

The defining quality of a corporation and the thing that makes it different
from a 3rd tier industry faction is that corporations have transferable shares
that will eventually be tradeable on some sort of in-game stock market. Also,
it may make sense to set a rule that corporations can own other corporations or
industries (see ownership above), but industry level factions cannot own
corporations.  Corporations get a faction channel and bboard by default.

### Tier 4: Industry

Basic business level.  Industry is used in its broadest sense to define any
business that is not a publicly traded corporation.  Industries get a faction
channel by default and a bboard when they have a minimum number of active
members (exact number TBD).  Industry factions will probably be able to
participate in some TBD manufacturing/sim-building system for generating
revenue.

### Tier 5: Organization

The lowest faction level that will eventually be player-creatable.  Could be
any type of organization from grass roots political movements to volunteer
organizations to pirate gangs.  Orgs do not get a channel or bboard by default,
but maybe they'll be allowed if they get large enough.

## Membership

Any player can belong to any number of factions.  The system is designed to be
similar to Google+ circles.  People have different things in common with
different groups of people.  If a player is a member of numerous factions,
chances are good that there is someone online that the person can RP with, and
that those two people have some sort of common ground based on a shared faction
relationship.

## Commands

All factions are referenced by their abbreviation by default, meaning all fac
abbrevs have to be unique.  

### Anyone

* +fac/invites
* +fac/reject (invite)
* +fac/join (faction)
* +fac/list

### Members

* +fwho/+fwho (fac)
* +fac/roster (fac)
* +fac/leave (fac)

### Leaders

* +fac/promote (fac)=(member)
* +fac/demote (fac)=(member)
* +fac/invite (player) to (fac)
* +fac/boot (fac)=(player)

### Admin

* +fac/set (fac)/(option)=(value)
* +fac/create (abbrev)=(full name)
* +fac/destroy (fac)

## Data Organization

Faction data is stored on its own object, the dbref of which is in the DATA
attribute on the functions object.  Each faction is stored in its own
attribute in the format: Name|Level|Members|Parent Fac|Leaders|IsHidden?|Channel

## Future Plans

* Hard rules for getting a faction channel or bboard?
* Resource based sim-building revenue generation system similar to RH?
* Stock market where corporation shares can be traded?
* Integration into commodity trading; generation of fac contracts, etc.?
* Designation of fac "bases" where fac members get various bonuses?
* Terraforming of planets as an IC method of expanding the grid?
