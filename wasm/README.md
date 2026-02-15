# Compiling dvisvgm to WebAssembly

This repository has a complete WASM build on the `wasm` branch. Here's how it all works.

## Prerequisites

1. **Install Emscripten** (the C/C++ to WebAssembly compiler):
   ```bash
   git clone https://github.com/emscripten-core/emsdk.git
   cd emsdk
   ./emsdk install latest
   ./emsdk activate latest
   source ./emsdk_env.sh
   ```

2. Verify `emcc` is on your PATH:
   ```bash
   emcc --version
   ```

## Building

From the **project root** (not the `wasm/` directory):

```bash
./wasm/build.sh
```

This produces two files: `wasm/dvisvgm.js` (ES6 module + glue code) and `wasm/dvisvgm.wasm`.

## What the build does

The build script (`wasm/build.sh`) compiles everything with `emcc` in three phases:

### 1. Stub kpathsea library

dvisvgm normally links against **kpathsea** (TeX's file-finder library). Since kpathsea depends on a full TeX Live installation, the WASM build replaces it with a stub (`wasm/kpathsea.cpp`) that provides the same C API but delegates file lookups to JavaScript via a JS-to-C bridge (`wasm/library_kpathsea.js`). The stub header is at `wasm/include/kpathsea/kpathsea.h`.

### 2. Bundled C/C++ libraries

The build compiles all vendored libraries from `libs/`:
- **clipper** — polygon clipping
- **md5** — hashing
- **potrace** — bitmap tracing
- **xxHash** — fast hashing
- **brotli** — compression (for WOFF2)
- **woff2** — web font encoding

**Freetype** and **zlib** come from Emscripten's ports system (`-s USE_FREETYPE=1 -s USE_ZLIB=1`).

### 3. dvisvgm sources

All `.cpp` files under `src/`, `src/fonts/`, `src/optimizer/`, and `src/ttf/` are compiled (excluding `MiKTeXCom.cpp`). The `wasm/config.h` disables Ghostscript and ttfautohint support.

### 4. Linking

Everything is linked into a single ES6 module with these key Emscripten flags:

| Flag | Purpose |
|------|---------|
| `MODULARIZE=1` + `EXPORT_ES6=1` | Produces an ES6 module exporting a factory function |
| `INVOKE_RUN=0` | Don't auto-run `main()` — call it manually via `callMain()` |
| `FORCE_FILESYSTEM=1` | Enable Emscripten's in-memory virtual filesystem (MEMFS) |
| `ALLOW_MEMORY_GROWTH=1` | Let the WASM heap grow dynamically |
| `EXPORTED_RUNTIME_METHODS` | Expose `FS`, `callMain`, `UTF8ToString` to JS |
| `--js-library library_kpathsea.js` | Register the JS-side kpathsea callback |

## Using it in a browser

### Minimal example

```javascript
import createDvisvgm from './dvisvgm.js';

const Module = await createDvisvgm({
  print: (msg) => console.log(msg),
  printErr: (msg) => console.error(msg),
});

// Write a DVI file into the virtual filesystem
const dviData = new Uint8Array(/* ... your DVI bytes ... */);
Module.FS.writeFile('/input.dvi', dviData);

// Convert (flags: -n = no fonts as paths, -p = page range)
Module.callMain(['-n', '-p', '1-', '/input.dvi', '-o', '/page-%p.svg']);

// Read back the SVG output
const svgFiles = Module.FS.readdir('/')
  .filter(f => f.endsWith('.svg'));

for (const f of svgFiles) {
  const svg = Module.FS.readFile('/' + f, { encoding: 'utf8' });
  document.body.innerHTML += svg;
}
```

### Font resolution

DVI files reference fonts by name (e.g. `cmr10`). dvisvgm needs the corresponding `.tfm` and `.pfb`/`.ttf` files. The demo in `wasm/index.html` solves this by:

1. **Running a local file server** that mirrors a TeX Live `texmf-dist` tree
2. **Loading an `ls-R` index** at startup to map font filenames to paths
3. **Providing a `kpse_load_file_remote` callback** that fetches fonts on demand via synchronous XHR and writes them into the MEMFS

The callback is wired through the `--js-library` bridge in `wasm/library_kpathsea.js`, which calls `Module.kpse_load_file_remote(namePtr, format)` on the JS side.

### Running the demo

```bash
cd wasm
npx serve .
```

Then open `http://localhost:3000` (or whatever port `serve` reports). You also need a font server — point it at your TeX Live `texmf-dist` directory with CORS enabled, e.g.:

```bash
cd /usr/local/texlive/2024/texmf-dist
npx serve . --cors -l 49258
```

## Limitations

- **No Ghostscript** — PostScript specials (EPS includes) won't work since GS can't be compiled to WASM
- **No ttfautohint** — disabled in `config.h`
- **Font provisioning is your responsibility** — you must either bundle needed fonts or fetch them at runtime (as the demo does)
- **Memory-only filesystem** — all files live in RAM via Emscripten's MEMFS
