#!/bin/sh
# Launch the fork's native Vulkan build with isolated game/user/cache paths.
set -eu
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
build="${LARECOMP_BUILD_DIR:-$root/out/build/linux-updated-release}"
if [ ! -x "$build/larecomp" ]; then
  echo "Native executable missing: $build/larecomp (see documentation/LINUX_VULKAN.md)" >&2
  exit 1
fi
if [ -n "${REXGLUE_SDK_DIR:-}" ]; then
  sdk_lib="$REXGLUE_SDK_DIR/lib"
else
  package_dir="$(sed -n 's/^rexglue_DIR:PATH=//p' "$build/CMakeCache.txt")"
  if [ -z "$package_dir" ] || [ ! -d "$package_dir/../.." ]; then
    echo "Set REXGLUE_SDK_DIR to the ReXGlue SDK install directory." >&2
    exit 1
  fi
  sdk_lib="$(CDPATH= cd -- "$package_dir/../.." && pwd)"
fi
for lib in librexruntime.so librexgpu-xenos.so; do
  if [ ! -e "$build/$lib" ]; then
    ln -s "$sdk_lib/$lib" "$build/$lib"
  fi
done
# Older SDK builds can serialize this enum as bare text, which rejects the
# entire TOML at next startup. Repair only known unquoted backend tokens.
if [ -f "$build/larecomp.toml" ]; then
  python3 - "$build/larecomp.toml" <<'PYCONFIG'
import pathlib, re
import sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
fixed = re.sub(r'(?m)^(graphics_backend\s*=\s*)(auto|vulkan|d3d12)([ \t]*(?:#.*)?)$',
               r'\1"\2"\3', text)
if fixed != text:
    path.with_suffix('.toml.before-enum-fix').write_text(text)
    path.write_text(fixed)
PYCONFIG
fi
cd "$root"
export DISABLE_LSFG="${DISABLE_LSFG:-1}"
export REX_LOG_LEVEL="${REX_LOG_LEVEL:-warn}"
export LD_LIBRARY_PATH="$build:$sdk_lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$build/larecomp" \
  --game_data_root="${MCLA_GAME_DATA:-$root/MCLA_Game_Files}" \
  --user_data_root="${LARECOMP_USER_DATA_DIR:-$root/out/user-data}" \
  --cache_root="${LARECOMP_CACHE_DIR:-$root/out/cache}" "$@"
