# Overview

System design for a game-based calendar that players can interact with.

## Goals (prioritized)

### Stage 1
* Provide a list of upcoming game events within a specified time frame.
* Allow players to create/edit/delete events of their own.  Allow admin to edit/delete any events.
* Store each event as a MongoDB document in a format that can be accessed in various mediums, whether in-game, via web interface, etc..
* Incorporate consideration of player timezone using existing Penn TZ functionality.

### Stage 2
* Allow players to "register" for an event, and allow events to have an optional max_participants setting.

### Stage 3
* Allow events to be assigned to a calendar group (see below).
* Allow in-game custom settings - certain group events can be shown in a certain color, in-game reminders, etc..

### Stage 4
* Allow a player to create/edit events seamlessly whether in-game or via web UI.
* Allow out-of-game or general settings - Email reminders, other stuff? (TBD)

### Stage 5
* Investigate possibility of tying in events and/or groups with a Google calendar that can be shared.
* Broadcast certain event reminders or a summary of upcoming events on the G+/FB/Twitter feeds.

## Calendar Groups

* Every event is associated with one or more calendar groups.
* By default, every event is in the "public" group.
* Groups can be public (anyone can join) or private (must be invited by a group member).
* Membership in a group is by character.

## User Interface

### Interaction with the calendar:
* +cal - All viewable upcoming events for the next 30 days.
* +cal (month abbrev) (year) - List events in specified month.
* +cal/view (id) - View event details.
* +cal/search (text) - Search for an event.

### Calendar personal settings:
* +cal/settings - Show all current settings and member groups.
* +cal/set (group)/color=(ansi) - Set default display color for group events.
* +cal/set (group)/reminders=(game|email) - Toggle reminders for in-game or email.

### Groups:
* +cal/groups - List of all member and public groups.
* +cal/newgroup (group) - Create a new group.
* +cal/delgroup (group) - Delete a group if you're the only member.  Any group for admin.
* +cal/invite (group)=(player) - Invite a player to a group you're in.
* +cal/set (group)/info=(string) - Set details about a group.

### Interaction with events:
* +event/new - Start a new event.
* +event/date (day) (month) (year) - Set the event time.
* +event/info (string) - Set the details.
* +event/loc (string) - Set the location.
* +event/addgroup (group) - Add to a group.
* +event/delgroup (group) - Remove from a group.
* +event/participants (num) - Maximum number of participants.
* +event/save - Save the event to Mongo.
* +event/edit (id) - Load up an existing event to edit.
* +event/delete (id) - Remove an event.
* +event/register (id) - Register for an event.
* +event/unregister (id) - Unregister from an event.

