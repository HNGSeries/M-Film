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
#include <fio-ml.h>
#include <notify_box.h>
#include <tasks.h>
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

/* Without the module the camera would just show Magic Lantern's own menu,
 * and nothing says why (#46). Once ML has had time to load its modules, say
 * so on the screen, and in ML/FILMROLL.LOG. */
extern char *module_lockfile;           /* module.c */

static void filmhook_note(const char *why)
{
    NotifyBox(15000, "M-Film didn't start: %s", why);
    FILE *f = FIO_CreateFileOrAppend("ML/FILMROLL.LOG");
    if (f)
    {
        char line[160];
        snprintf(line, sizeof(line), "filmhook: the film OS module isn't loaded: %s\n", why);
        FIO_WriteFile(f, line, strlen(line));
        FIO_CloseFile(f);
    }
}

static void filmhook_task()
{
    for (int i = 0; i < 30 && filmos_menu_open == (void *) ret_0; i++)
        msleep(500);                    /* ML loads modules a few seconds after start-up */
    if (filmos_menu_open != (void *) ret_0) return;
    uint32_t size;
    if (module_get_number("filmos") < 0)
        filmhook_note("ML/modules/filmos.mo isn't on the card. Copy everything in the zip again.");
    else if (FIO_GetFileSize(module_lockfile, &size) == 0)
        filmhook_note("Magic Lantern skipped its modules: the camera wasn't switched off cleanly last time. Switch off with the switch, then on.");
    else
        filmhook_note("its module didn't load. Magic Lantern's Modules tab (MENU) says why: please send us that line.");
}

TASK_CREATE("filmhook_task", filmhook_task, 0, 0x1f, 0x1000);

