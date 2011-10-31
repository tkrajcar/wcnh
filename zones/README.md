# Wing Commander: New Horizon Zone Management System

This is where code that has to do with building and/or grid management goes.

## Commands
* +zone/list - Return a hierarchy of all zones.
* +zone/list (partial zone name) - Same as above but with limited return.
* +zone/checkout (zone name) - Check out a BC for use.

## New Zone Setup Checklist
* @pcreate BC
* @create ZMO
* @lock ZMO==BC
* @tel ZMO=BC
* @lock/zone ZMO==ZMO
* @chzone BC=ZMO
* @chzone ZMO=Parent ZMO
* @lset ZMO/chzone=wizard
* @lset ZMO/zone=wizard
* @lset BC/chzone=wizard
* &BC ZMO=BC
* @set ZMO/BC=wizard
* @squota BC=+amount
* Crack beer
