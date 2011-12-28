# Wing Commander: New Horizon Zone Management System

This is where code that has to do with building and/or grid management goes.

## Commands
* +zone/list - Return a hierarchy of all zones.
* +zone/list (partial zone name) - Same as above but with limited return.
* +zone/checkout (zone name) - Check out a BC for use.

## New Zone Setup Checklist

Someday, there will be automation for this process.

Before creating a new city ZMO and BC, make sure that the system and planet are  zoned. 
@find <system name>.  There should be a room AND an object with the same name.
The object is the system ZMO, and should be zoned to the Galaxy ZMO (#222).  The planet should 
be zoned to the system ZMO.

Once that is done, proceed with the following.

* @pcreate BC
* @create ZMO
* @lock ZMO==BC
* @lock BC==BC
* @lock/zone ZMO==ZMO
* @lock/chzone ZMO=flag^wizard
* @lock/chzone BC=flag^wizard
* @chzone BC=ZMO
* @chzone ZMO=Parent ZMO
* @lset ZMO/chzone=wizard
* @lset ZMO/zone=wizard
* @lset BC/chzone=wizard
* &BC ZMO=BC
* @set ZMO/BC=wizard
* @squota BC=+amount
* @power BC=builder
* @chown ZMO=BC
* @set ZMO=!halt
* @tel ZMO=BC
* Crack beer
