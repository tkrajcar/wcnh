# WCNH Softcode Coding Standards

## File & Directory Organization

* Create a directory for your system (faction, chargen, globals, etc).
* Create one file per object in that directory using the `.mush` extension (`chargen/functions.mush`).
* In general, commits should be made against `master` which is assumed to be identical to code running on the game. If you are doing some serious heavy lifting and need to make multiple pushed commits that will break existing functionality, set up a separate testbed game (see Rince for a fresh DB) and use a branch so that we can still make urgent fixes to the game without accidentally incorporating your unfinished work!

## Tabs and line endings

* No tab characters, use two space indentations.
* Linux line endings only, please!
* * Linux/Mac users, run: `git config --global core.autocrlf input`
* * Windows users, run: `git config --global core.autocrlf true`

## Attribute and command naming
* IC commands do not start with a `+`. OOC commands do.
* In general, use attribute prefixes of `cmd.`, `fn.`, `map.`, `filter.` and so on.
* If you are working on a very complex system that has lots of attributes on a global, room parent, etc, make sure and set your non-command-matching attributes `no_command` so the game doesn't search them everytime anybody does anything.

## RPC functionality
* TODO