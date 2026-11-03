/* The film OS as a module (build_fork.sh --module): all that stays in
 * autoexec.bin. The film OS itself (filmroll.c, fos_*.c) is ML/modules/filmos.mo,
 * loaded after boot into Canon's memory, so it doesn't count against what the
 * camera can spare at power on (MEMORY.md).
 *
 * These are the three calls ML's core makes into the film OS. Each goes to
 * the module once it is loaded; without it (missing, failed to load, or ML
 * skipped loading modules after a crash) they answer as if there were no
 * film OS, so the camera still has Magic Lantern's own menu. */

#include <dryos.h>
#include <module.h>
#include "filmroll.h"

/* defined in the module (filmroll.c); 0 until it is loaded */
static int (*filmos_key_used)(struct event *event) = MODULE_FUNCTION(filmos_key_used);
static int (*filmos_menu_open)(void)               = MODULE_FUNCTION(filmos_menu_open);
static int (*filmos_overlays)(void)                = MODULE_FUNCTION(filmos_overlays);

int handle_filmroll_keys(struct event *event)
{
    return filmos_key_used(event) ? 0 : 1;
}

int filmroll_menu_requested()
{
    return filmos_menu_open();
}

int filmroll_overlays_active()
{
    return filmos_overlays();
}
