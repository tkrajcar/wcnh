/*-----------------------------------------------------------------
 * Local functions
 *
 * This file is reserved for local functions that you may wish
 * to hack into PennMUSH. Read parse.h for information on adding
 * functions. This file will not be overwritten when you update
 * to a new distribution, so it's preferable to add new functions
 * here and leave the other fun*.c files alone.
 *
 */

/* Here are some includes you're likely to need or want.
 * If your functions are doing math, include <math.h>, too.
 */
#include "copyrite.h"
#include "config.h"
#include <string.h>
#include "conf.h"
#include "externs.h"
#include "parse.h"
#include "confmagic.h"
#include "function.h"
#include "match.h"
#include "lock.h"

void local_functions(void);

/* Here you can use the new add_function instead of hacking into function.c
 * Example included :)
 */

#ifdef EXAMPLE
FUNCTION(local_fun_silly)
{
  safe_format(buff, bp, "Silly%sSilly", args[0]);
}

#endif

FUNCTION(fun_lzone)
{
  dbref it;
  dbref zone;
  int i = 0;

  it = match_thing(executor, args[0]);
  if (!GoodObject(it)) {
    safe_str(T(e_notvis), buff, bp);
    return;
  } else if (!Can_Examine(executor, it)) {
    safe_str(T(e_perm), buff, bp);
    return;
  }
  zone = Zone(it);
  if (!GoodObject(zone)) {
    safe_str("#-1", buff, bp);
    return;
  }

  while (GoodObject(zone)) {
    if (i) {
      if (safe_chr(' ', buff, bp))
        break;
    }
    i++;
    safe_dbref(zone, buff, bp);
    it = zone;
    zone = Zone(zone);
    if (zone == it)
      break;
  }
}

void
local_functions(void)
{
#ifdef EXAMPLE
  function_add("SILLY", local_fun_silly, 1, 1, FN_REG);
#endif
  function_add("LZONE", fun_lzone, 1, 1, FN_REG);
}
