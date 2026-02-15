#ifndef CONFIG_H
#define CONFIG_H

#define PACKAGE_NAME "dvisvgm"
#define PROGRAM_NAME "dvisvgm"
#define PACKAGE_VERSION "3.6"
#define PROGRAM_VERSION "3.6"
#define VERSION "3.6"
#define HOST_SYSTEM "wasm32-unknown-emscripten"

#define HAVE_LIBZ 1
#define HAVE_FREETYPE 1
#define HAVE_SYS_TIME_H 1
#define HAVE_UNISTD_H 1

/* Disable features that are hard to support in Wasm for now */
#define DISABLE_GS 1
#define DISABLE_TTFAUTOHINT 1

#endif
