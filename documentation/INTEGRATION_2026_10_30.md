# Upstream integration build (2026-10-30)

Branch: `integration/upstream-2026-10-30`, based on `build/linux-vulkan`.
Upstream snapshot: `2f04298` (142 upstream commits since the original base).
The stable checkout, binary, Lutris entry and career save are not replaced.

## Merge handling

- Retain Linux GTK linkage alongside upstream's optional Plume build.
- Retain platform guards around the legacy D3D12 renderer.
- Preserve upstream's rewritten native pause forms; apply Linux window-close
  handling to the new QUIT confirmation action rather than restoring the old menu.
- Retain both local diagnostic exclusions and upstream identity-key exclusions.
- Ignore the game-data path whether it is a directory or a build-only symlink.
- Use the SDK tiled-address helper directly for keyboard glyphs, avoiding a
  link dependency on the excluded D3D12 renderer. Query its optional debug-overlay
  cvar through the registry so non-Windows builds do not require its storage.

## Build-only reproduction

Supply compatible extracted Complete Edition data in `MCLA_Game_Files/` and set
`SDK` to the compatible Linux ReXGlue 0.10.0 installation. The existing SDK is
reused read-only; it is not rebuilt or overwritten.

```sh
"$SDK/bin/rexglue" codegen larecomp_manifest.toml
cmake -S . -B out/build/linux-integration-release -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_COMPILER=/usr/lib/llvm20/bin/clang++ \
  -DCMAKE_CXX_FLAGS=-mssse3 \
  '-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG' \
  -DCMAKE_PREFIX_PATH="$SDK" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DLARECOMP_GPU=OFF
cmake --build out/build/linux-integration-release --parallel 4
```

This uses the established Xenos Vulkan backend. Upstream's experimental Plume
renderer remains disabled, matching its non-Windows default; the new Plume
rendering features are not part of this artifact.

## Validation boundary

The requested task is compilation only: do not execute the game as a verification
step. Verify the ELF format, linked libraries and actual `-O3 -DNDEBUG` compile
commands statically. Build logs are under `out/integration/`.

Before any later authorized gameplay trial, create independent writable game,
user-data and cache directories. A read-only/build-only game-data symlink must
not silently become a shared writable runtime installation. Use
`LARECOMP_BUILD_DIR` to select the integration artifact; keep the stable Lutris
entry unchanged until the new version is actually tested.

A successful build does not establish gameplay, audio, save compatibility,
performance, quit handling or long-session stability. These remain untested.
# Linux input follow-up

The first runtime test exposed a shared-SDL conflict. Unlike the Windows DLL
layout, the Linux executable resolves its SDL calls through `librexruntime.so`.
The new menu pad layer initialized gamepads before the SDK installed its event
watch and disabled gamepad events globally. This could hide initially connected
controllers and suppress input from controllers connected later.

Linux menu polling now waits for SDK gamepad initialization and does not disable
events or controller backends. Windows keeps its separate-copy behavior. The
wheel thread's Windows-only backend exclusions are also guarded by platform.
Pre-runtime dialogs on Linux remain keyboard-operable; controller menu polling
becomes available after SDK input initialization.

For keyboard-as-controller testing, enable `mnk_mode = true` in the isolated
runtime configuration. Start is Return or X; A is the SDK's configured binding.
This setting is local to the trial build and is not a stable-install change.
