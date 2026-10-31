# Counters-disabled FidelityFX Linux trial

Branch: `experiment/fidelityfx-vulkan-2026-10-30`.
Game worktree: `/mnt/predator-2/RecompGames/LARecomp-fidelityfx`.
SDK snapshot: `/mnt/predator-2/RecompGames/LARecomp-fidelityfx-sdk`.

The SDK snapshot includes the existing SDK's local compatibility patches and
independent copies of dependency sources. Original SDK source/build/install and
working game executables are not modified. Baseline binary/config/save hashes
are under ignored `out/trial/baseline.json`; the original SDK local diff is
captured in `out/trial/original-sdk-local.patch`.

## SDK configuration

```sh
cmake -S . -B out/build/linux-fidelityfx-release -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=/usr/lib/llvm20/bin/clang \
  -DCMAKE_CXX_COMPILER=/usr/lib/llvm20/bin/clang++ \
  -DCMAKE_CXX_FLAGS=-mssse3 \
  '-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG' \
  -DCMAKE_INSTALL_PREFIX="$PWD/out/install/linux-fidelityfx-release" \
  -DREXGLUE_ENABLE_TRACY=OFF -DREXGLUE_ENABLE_PERF_COUNTERS=OFF \
  -DREXGLUE_ENABLE_FIDELITYFX=ON -DREXGLUE_FIDELITYFX_BACKEND=vk \
  -DREXGLUE_USE_VULKAN=ON -DREXGLUE_BUILD_TESTS=OFF -DBUILD_TESTING=OFF \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

FidelityFX is pinned by the SDK to `eee08db1688ac3d1275a70b728f4a8ba22914213`.
Its FSR3 upscaler provider is version 3.1.4. Frame-generation provider is disabled
by the SDK integration. There is no FSR4 selector/provider integrated here.

On Arch, `/bin/sh` expands the shader compiler's `{0,1}` permutation descriptors
into multiple conflicting `-D` arguments. Apply
`patches/fidelityfx-linux-permutation-quoting.patch` inside the fetched FidelityFX
source directory, then regenerate CMake. This quotes each permutation descriptor
for UNIX without changing the shader algorithms. CMake VERBATIM alone did not
protect brace expansion. The dependency uses its Windows shader compiler under
Wine at build time only; the game/runtime remain native Linux. Use the isolated
`WINEPREFIX` below, not a game prefix.

```sh
WINEPREFIX=/mnt/predator-2/RecompGames/LARecomp-fidelityfx/out/wine-shader-tools \
WINEDEBUG=-all cmake --build out/build/linux-fidelityfx-release --parallel 4
cmake --install out/build/linux-fidelityfx-release
```

## Temporal FSR limitations

The existing generic Vulkan presenter passes the colour image as both depth and
motion input, fixes jitter at zero and resets history on every dispatch. This
is not a proper game-native temporal FSR2/3 integration. The isolated SDK applies
`patches/sdk-temporal-input-fallback.patch` to keep the existing spatial EASU/RCAS
path and log an explicit fallback instead of dispatching with invalid inputs.
Selecting FSR3 is therefore NOT proof of temporal FSR3 or frame generation.
Implementing those needs real game depth, motion/jitter, history management and
validation. No FSR4 support is claimed.

## Comparison procedure

Keep the baseline's improved settings: traffic range 400 m, MSAA disabled,
resolution scale 2, and all other preferences unchanged. First compare the new
counters-disabled SDK with `present_effect=bilinear`, so an image-quality change
cannot explain the difference. Build compilation must finish before driving.

For a separate spatial FSR test, use `present_effect=fsr` and a lower internal
resolution, retaining the same display mode. FSR does not reduce traffic AI or
physics and does not provide a free gain at the same internal resolution. With
integer resolution scales, 1x-to-1440p is a substantial quality tradeoff; compare
text, fences, foliage and motion, not just a title screenshot. FSR quality mode
labels in this SDK should not be assumed to lower the guest GPU's rendering
resolution automatically.

Use independent copied game data, saves and cache paths. No Lutris switch or
replacement of the improved working executable is part of this experiment.

## Observed validation

- Optimized SDK and game builds passed; compile commands omit the SDK counter
  define for both, while all 120 translated game units retain `-O3 -DNDEBUG`.
- Game timing-log and debug-overlay readers are guarded when SDK counters are
  compiled out. Unavailable counters are labelled unavailable, not fake zeros.
- New runtime, Xenos Vulkan plugin and `libamd_fidelityfx_vk.so` were verified
  mapped from the isolated SDK/build, not the working baseline install.
- Diagnostic launch with `present_effect=fsr`, `resolution_scale=1` rendered
  startup screens and logged actual EASU and RCAS draws at 2560x1440.
  This establishes the spatial effect path, not gameplay quality or FPS gains.
- Diagnostic run closed gracefully. Comparison launch uses normal warning-level
  logging, `present_effect=bilinear`, resolution scale 2, range 400 m, MSAA off.
- Baseline executable/config/save and original installed SDK hashes remained
  unchanged. New saves/cache are independent copies. Lutris is unchanged.
- Experimental SDK auto-registration in the CMake user package registry was
  retired; existing SDK registry entries were preserved. Game configuration pins
  `rexglue_DIR:PATH` explicitly to the isolated install.

Game build:

```sh
SDK=/mnt/predator-2/RecompGames/LARecomp-fidelityfx-sdk/out/install/linux-fidelityfx-release
"$SDK/bin/rexglue" codegen larecomp_manifest.toml
cmake -S . -B out/build/linux-fidelityfx-release -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=/usr/lib/llvm20/bin/clang++ \
  -DCMAKE_CXX_FLAGS=-mssse3 '-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG' \
  -Drexglue_DIR:PATH="$SDK/lib/cmake/rexglue" -DCMAKE_PREFIX_PATH="$SDK" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DLARECOMP_GPU=OFF
cmake --build out/build/linux-fidelityfx-release --parallel 4
LARECOMP_BUILD_DIR="$PWD/out/build/linux-fidelityfx-release" ./scripts/play_linux.sh --log_level=warn
```

The optional spatial-pass diagnostic SDK patch logs each FSR pass once per
rendering thread. Apply it after the temporal fallback patch. No actual
performance improvement, controller gameplay, or temporal FSR3/FSR4 support is
claimed by these startup checks.
