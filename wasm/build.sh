#!/bin/bash

# Exit on error
set -e

# Check if emcc is available
if ! command -v emcc &> /dev/null; then
    echo "emcc not found. Please install Emscripten and make sure it's in your PATH."
    exit 1
fi

PROJECT_ROOT=$(pwd)
WASM_DIR=$PROJECT_ROOT/wasm
SRC_DIR=$PROJECT_ROOT/src
LIBS_DIR=$PROJECT_ROOT/libs

# Prepare wasm directory
mkdir -p "$WASM_DIR/obj"

INCLUDES="-I$WASM_DIR -I$WASM_DIR/include -I$SRC_DIR -I$LIBS_DIR/boost -I$LIBS_DIR/clipper -I$LIBS_DIR/potrace -I$LIBS_DIR/xxHash -I$LIBS_DIR/woff2/include -I$LIBS_DIR/brotli/include -I$LIBS_DIR/variant/include -I$LIBS_DIR/md5"
DEFINES="-DHAVE_CONFIG_H -DVERSION=\"3.6\" -DPACKAGE_VERSION=\"3.6\" -DHOST_SYSTEM=\"wasm32-unknown-emscripten\""

echo "Compiling dummy kpathsea..."
emcc -c "$WASM_DIR/kpathsea.cpp" -o "$WASM_DIR/obj/kpathsea.o" $INCLUDES $DEFINES

echo "Compiling bundled libraries..."

# Clipper
emcc -c "$LIBS_DIR/clipper/clipper.cpp" -o "$WASM_DIR/obj/clipper.o" $INCLUDES $DEFINES

# MD5
emcc -c "$LIBS_DIR/md5/md5.c" -o "$WASM_DIR/obj/md5.o" $INCLUDES $DEFINES

# Potrace
for f in curve decompose potracelib trace; do
    emcc -c "$LIBS_DIR/potrace/$f.c" -o "$WASM_DIR/obj/potrace_$f.o" $INCLUDES $DEFINES
done

# xxHash
emcc -c "$LIBS_DIR/xxHash/xxhash.c" -o "$WASM_DIR/obj/xxhash.o" $INCLUDES $DEFINES

# Brotli
for f in "$LIBS_DIR/brotli/common"/*.c "$LIBS_DIR/brotli/enc"/*.c; do
    if [ -f "$f" ]; then
        emcc -c "$f" -o "$WASM_DIR/obj/brotli_$(basename $f .c).o" $INCLUDES $DEFINES
    fi
done

# Woff2
for f in font glyph normalize table_tags transform variable_length woff2_common woff2_enc woff2_out; do
    emcc -c "$LIBS_DIR/woff2/src/$f.cc" -o "$WASM_DIR/obj/woff2_$f.o" $INCLUDES $DEFINES -I"$LIBS_DIR/woff2/include" -I"$LIBS_DIR/brotli/include"
done

echo "Compiling dvisvgm source files..."

# Collect all .cpp files in src, src/fonts, src/optimizer, src/ttf
CPP_FILES=$(find "$SRC_DIR" -maxdepth 1 -name "*.cpp")
CPP_FILES="$CPP_FILES $(find "$SRC_DIR/fonts" -name "*.cpp")"
CPP_FILES="$CPP_FILES $(find "$SRC_DIR/optimizer" -name "*.cpp")"
CPP_FILES="$CPP_FILES $(find "$SRC_DIR/ttf" -name "*.cpp")"

# Exclude MiKTeX specific files
CPP_FILES=$(echo "$CPP_FILES" | grep -v "MiKTeXCom.cpp")

for f in $CPP_FILES; do
    rel_path=${f#$PROJECT_ROOT/}
    obj_name=$(echo $rel_path | tr '/' '_').o
    echo "Compiling $rel_path..."
    emcc -c "$f" -o "$WASM_DIR/obj/$obj_name" $INCLUDES $DEFINES -s USE_FREETYPE=1 -s USE_ZLIB=1 -std=c++11
done

echo "Linking..."
emcc "$WASM_DIR/obj"/*.o -o "$WASM_DIR/dvisvgm.js" \
    -s USE_FREETYPE=1 -s USE_ZLIB=1 \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s EXIT_RUNTIME=0 \
    -s INVOKE_RUN=0 \
    -s FORCE_FILESYSTEM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_ES6=1 \
    -s EXPORTED_RUNTIME_METHODS="['FS', 'callMain', 'UTF8ToString']" \
    --js-library "$WASM_DIR/library_kpathsea.js" \
    --export-dynamic

echo "Build complete: wasm/dvisvgm.js and wasm/dvisvgm.wasm"
