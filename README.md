# Wing Commander: New Horizon MUSH
Complete source code from an up-and-running sci-fi MUSH, including extensive MongoDB-backed systems coded in Ruby.

**Questions / need help? Connect to the support MUSH at wcmush.com 2199**

## Introduction
This page indexes the public source for [Wing Commander: New Horizon MUSH](http://www.wcmush.com/), a text-based online storytelling game set in the Wing Commander video game universe. The game is no longer running as a "real" game, but you can connect to **wcmush.com 2199** if you want to see it up and running. The code and basic database has been made available, for you to use as you wish.

This codebase contains a number of unusual customizations to PennMUSH - principally among them, a complete implementation of a JSON API that allows for the connection of external processes to exchange data in real-time with the MUSH process (including support for asynchronous callbacks). There is a complete implementation provided in Ruby, with many detailed coded systems suitable for a sci-fi game, but the PennMUSH side of the JSON system could also be used to connect to other platforms.

The systems code is a fusion of all-Ruby systems (that have very basic softcode hooks to initiate them) and a few all-softcode systems that were written before the Ruby layer was finished. All the Ruby systems rely on MongoDB for data storage.

## Features

It's a complete and full codebase from an up and running game - most of the code has been thoroughly tested, debugged, etc. Very little of the code is theme-specific - the parts that are could either be unused or replaced.

Included in this codebase are complete and fully-implemented systems for:

* Multi-racial chargen (softcoded) - loosely based on the FUDGE system
* MongoDB-backed bulletin boards, following the familiar Myrddin command scheme
* Event calendars
* Hand-to-hand combat, with weapons, detailed damage modeling based on race, etc
* IC communications via 'subspace' (instant channels) and 'tightbeam' (message-based/IC mail)
* Contracts system for creating TPs in an IC way
* Economy, with banks and personal accounts
* Ship cargo mission system, with generated missions based on a basic commodity supply & demand model
* Full "semi/virtual" item system for creating items with MongoDB attributes attached
* Full RP (pose, say, etc) logging system, for player 'scrollback', automated XP awards, and admin review
* Basic space system (softcoded) with ship movement, classes, etc. Ship combat is not supported.
* Faction/organization system (softcoded)
* Basic globals (+finger, who, etc)
* Room parents, exit parents, etc.

## Getting Started

The easiest way to take a look at the full code in action is to connect to the 'support' MUSH at **wcmush.com 2199**. This is the full game up and running, and the developers and I are usually idling there and may be able to help give you a quick tour.

For development purposes, I highly recommend using [Vagrant](https://www.vagrantup.com/). I've provided a Vagrantfile in the repository to get you up and running quickly.

1. Install Ruby if you don't already have it. See [ruby-lang.org](ruby-lang.org) for information, since this wildly depends on what platform you are using.
2. Install virtualbox from [virtualbox.org](virtualbox.org).
3. Run `gem install vagrant`
4. Clone this repository: `git clone git://git@github.com/tkrajcar/wcnh.git`
5. Run `cd wcnh`
6. Run `gem install vagrant`
7. Run `vagrant up`
8. Wait while Vagrant does a lot of hard work for you.
9. Run `vagrant ssh`
10. Run `sh /vagrant/game/restart`
11. On your host (not the VM), connect to localhost, port 2199. The default #1 password is: **ggAioK187yx4cD5q**

Setting up an actual server to run the game will vary depending on your choice of Linux distribution. If you can use Ubuntu 12.04, see [the README.WCNH.SERVER](https://github.com/tkrajcar/wcnh/blob/master/README.WCNH.SERVER) file for step-by-step instructions.

## Creating A New System

If you're interested in adding new Ruby code/systems, there's [a wiki page](https://github.com/tkrajcar/wcnh/wiki/Creating-A-New-Ruby-System-Walkthrough) that walks you through a simple example.

## Other Repositories

There are two other repositories that might interest you:

* [wcnh_web](http://www.github.com/tkrajcar/wcnh_web) - the Rails source of [wcmush.com](http://www.wcmush.com)
* [pennjson](http://www.github.com/tkrajcar/pennjson) - a "reference implementation" of vanilla PennMUSH + JSON + Ruby without any WCNH systems or code

## Support

This is technically offered as-is, with no warranty of its suitability for any purpose. I am happy to accept pull requests for bugs and will offer support via either issues or email as best as I can.

If you end up using this, please let me know! I'd love to check out what you do with it. :)

You can email me at allegro@conmolto.org, I'm usually on Freenode as tkrajcar, and you can connect to wcmush.com 2199 to poke around the "real" game that this code came out of - I (Rince) usually am idling on there.

## Credits

In addition to myself (@tkrajcar, known on MU*s as Rince), the following people helped create this project, and deserve thanks:

* The PennMUSH->JSON and 'reference' Ruby-> JSON implementation were developed by [kymoon](https://github.com/kymoon).
* [nevern02](https://github.com/nevern02) collaborated throughout the development and wrote several complete systems.
* [feemjmeem](https://github.com/feemjmeem) contributed patches and features.
* [capelio](https://github.com/capelio) designed the initial specifications for the space system, and did the visual design of [wcmush.com](http://www.wcmush.com/).
