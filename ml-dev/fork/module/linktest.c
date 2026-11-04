/* linktest: link ML/modules/filmos.mo the way the camera's module loader does,
 * with Magic Lantern's own TCC (platform/<cam>/build/tcc/libtccx.o), on a PC
 * under qemu-arm. build_fork.sh --module runs it when qemu-arm is installed.
 *
 *   linktest filmos.mo <cam>.sym      exit 0: linked, and the module's info found
 *
 * It caught the module that crashed the camera's loader in 0.1.4 (#46, #48):
 * libgcc's unwind tables (.ARM.exidx), which ML's TCC can't load. */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include "libtcc.h"

/* what ML's TCC asks of its host (src/tcc-glue.c, src/mem.c on the camera) */
void *__mem_malloc(size_t n, unsigned flags, const char *file, unsigned line) { (void) flags; (void) file; (void) line; return malloc(n); }
void __mem_free(void *p) { free(p); }
void _tcc_exit(int code) { printf("linktest: tcc exit(%d)\n", code); exit(3); }
int _tcc_open(const char *path, int flags) { (void) flags; return open(path, O_RDONLY); }
int _tcc_read(int fd, void *buf, int n) { return read(fd, buf, n); }
int _tcc_close(int fd) { return close(fd); }
int _tcc_lseek(int fd, int off, int whence) { return lseek(fd, off, whence); }

int main(int argc, char **argv)
{
    if (argc != 3) { printf("usage: linktest filmos.mo <cam>.sym\n"); return 2; }
    TCCState *s = tcc_new();
    tcc_set_options(s, "-nostdlib");
    FILE *f = fopen(argv[2], "r");
    if (!f) { printf("linktest: can't read %s\n", argv[2]); return 2; }
    char line[256];
    int n = 0;
    while (fgets(line, sizeof(line), f))
    {
        unsigned a;
        char name[200];
        if (sscanf(line, "%x %199s", &a, name) == 2) { tcc_add_symbol(s, name, (void *) a); n++; }
    }
    fclose(f);
    if (tcc_add_file(s, argv[1]) < 0) { printf("linktest: TCC can't load %s\n", argv[1]); return 1; }
    int size = tcc_relocate(s, NULL);
    void *buf = size > 0 ? malloc(size) : 0;
    if (!buf || tcc_relocate(s, buf) < 0) { printf("linktest: TCC can't link %s\n", argv[1]); return 1; }
    if (!tcc_get_symbol(s, "__module_info_filmos")) { printf("linktest: no module info in %s\n", argv[1]); return 1; }
    printf("linktest: %s links (%d bytes, %d core symbols)\n", argv[1], size, n);
    return 0;
}
