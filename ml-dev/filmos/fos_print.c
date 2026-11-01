/* fos_print: reading a print (the BMP the darkroom writes, fos_dev.c).
 *
 * Kept apart from the darkroom so every build can show prints: the shelf's
 * sample of each film is one, also in builds made --no-darkroom.
 */

#include "fos.h"
#include "fos_dev.h"
#include <string.h>

static int u16le(const uint8_t *p) { return p[0] | p[1] << 8; }
static unsigned u32le(const uint8_t *p) { return p[0] | p[1] << 8 | p[2] << 16 | (unsigned) p[3] << 24; }

static int is_print(const uint8_t *h)
{
    return h[0] == 'B' && h[1] == 'M' && u32le(h + 10) == FOS_BMP_PIXELS && u32le(h + 18) == FOS_PRINT_W
        && !memcmp(h + FOS_BMP_META, "FOP2", 4);
}

int fos_print_thumb(const char *path, uint8_t *thumb)
{
    void *f = fos_port_open(path, 0);
    if (!f) return 0;
    static uint8_t h[FOS_BMP_PIXELS];
    int ok = fos_port_read(f, h, FOS_BMP_PIXELS) == FOS_BMP_PIXELS && is_print(h)
          && fos_port_seek(f, FOS_BMP_THUMB) >= 0 && fos_port_read(f, thumb, FOS_THUMB_SIZE) == FOS_THUMB_SIZE;
    fos_port_close(f);
    return ok;
}

int fos_print_load(const char *path, struct fos_print *p)
{
    memset(p, 0, sizeof(*p));
    void *f = fos_port_open(path, 0);
    if (!f) return 0;
    static uint8_t h[FOS_BMP_PIXELS];
    int ok = fos_port_read(f, h, FOS_BMP_PIXELS) == FOS_BMP_PIXELS && is_print(h);
    if (ok)
    {
        const uint8_t *m = h + FOS_BMP_META;
        p->film = m[4];
        p->frame = u16le(m + 6);
        memcpy(p->when, m + 8, 19);
        memcpy(p->fstop, m + 28, 7);
        p->x0 = u16le(m + 36);
        p->w = u16le(m + 38);
        if (!p->w || p->x0 + p->w > FOS_PRINT_W) p->x0 = 0, p->w = FOS_PRINT_W;
        for (int i = 0; i < FOS_PRINT_COLOURS; i++)
        {
            const uint8_t *q = h + FOS_BMP_PAL + 4 * (i + 1);
            p->pal[i][0] = q[2]; p->pal[i][1] = q[1]; p->pal[i][2] = q[0];
        }
        p->px = fos_port_alloc(FOS_PRINT_W * FOS_PRINT_H);
        ok = p->px && fos_port_read(f, p->px, FOS_PRINT_W * FOS_PRINT_H) == FOS_PRINT_W * FOS_PRINT_H;
    }
    fos_port_close(f);
    if (!ok) fos_print_free(p);
    return ok;
}

void fos_print_free(struct fos_print *p)
{
    fos_port_free(p->px);
    p->px = 0;
}
