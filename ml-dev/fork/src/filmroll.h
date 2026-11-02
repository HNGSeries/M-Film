#ifndef _filmroll_h_
#define _filmroll_h_

struct event;

/* button hook, called from handle_common_events_by_feature; 0 = handled */
int handle_filmroll_keys(struct event *event);

/* called instead of opening the Magic Lantern menu (menu.c). With the film OS
 * as a module (FEATURE_FILMOS_MODULE): 1 = it took it, 0 = open ML's menu as
 * usual (the module isn't loaded) */
#if defined(FEATURE_FILMOS_MODULE) || defined(MODULE)
int filmroll_menu_requested();
#else
void filmroll_menu_requested();
#endif

/* ML's own LiveView overlays stay out of the way of the film OS and the
 * viewfinder HUD (always, in this fork) */
int filmroll_overlays_active();

#endif
