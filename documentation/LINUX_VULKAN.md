# Experimental native Linux/Vulkan build

This branch builds LARecomp as an optimized Linux ELF application using the
standard ReXGlue Xenos Vulkan plugin. It does not port the experimental native
D3D12 renderer to Vulkan.

## Changes

- Exclude the experimental `src/native_gfx/` sources outside Windows and guard
  their application entry points; retain normal Xenos plugin presentation.
- Use POSIX local-time conversion on non-Windows systems.
- Use a standard C++ thread/sleep for the mod part probe on Linux.
- Include the size type explicitly and link GTK 3 for file-picker dialogs.
- Send Linux menu quit through SDL window-close handling, which stops the title.

## Build

Requires the existing patched Linux ReXGlue SDK 0.10.0, Clang 20, Ninja, and GTK 3.
Set `SDK` to the SDK install directory and supply extracted Complete Edition game
files in `MCLA_Game_Files/`. No game data is tracked by Git.

```sh
"$SDK/bin/rexglue" codegen larecomp_manifest.toml
cmake -S . -B out/build/linux-amd64-release -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_COMPILER=/usr/lib/llvm20/bin/clang++ \
  -DCMAKE_CXX_FLAGS=-mssse3 \
  '-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG' \
  -DCMAKE_PREFIX_PATH="$SDK"
cmake --build out/build/linux-amd64-release --parallel 4
```

Inspect actual generated compile commands for `-O3 -DNDEBUG`; do not infer
optimization merely from the Release build-directory name.

## Local trial layout

`./scripts/play_linux.sh` launches the native build with independent
`MCLA_Game_Files/`, `out/user-data/`, and `out/cache/` directories. Existing saves
may be copied into `out/user-data/` while the game is closed; do
not symlink another installation’s writable save directory. SDK shared libraries
are reused read-only. The launcher finds the SDK through the build’s CMake cache;
`REXGLUE_SDK_DIR` may override its install directory. `LARECOMP_BUILD_DIR`,
`MCLA_GAME_DATA`, `LARECOMP_USER_DATA_DIR`, and `LARECOMP_CACHE_DIR` override the
local defaults.

On Wayland, merge these values into
`out/build/linux-amd64-release/larecomp.toml` without replacing other settings:

```toml
vulkan_allow_present_mode_immediate = false
vulkan_allow_present_mode_mailbox = false
fps_limit = 60
real_frame_delta = true
vsync = false
```

The launcher defaults to `REX_LOG_LEVEL=warn` to avoid logging overhead and
`DISABLE_LSFG=1` for a plain native-rendering baseline. Set either environment
variable explicitly to override it.

## Verification and limits

- Native ELF Release executable built successfully with optimization enabled.
- Vulkan initialized on RADV and the rendered title screen was visually checked.
- Copied save was detected and SDL audio output initialized.
- Driving, audio quality, long-session stability and the in-game quit action
  still require player testing; a successful title-screen launch is not a
  performance or gameplay validation.
- Windows-specific optional features (including the experimental D3D12 renderer
  and the host MP3 player) are not provided or validated by this Linux build.

Build and launch logs are under `out/native-attempt/`; runtime logs and the
applied-configuration report are under `logs/`.

## Keeping this fork up to date

`origin` is the personal fork; `upstream` is `mzzvxm/LARecomp`. The maintained
build branch is `build/linux-vulkan`, not upstream's `main`.

```sh
git switch build/linux-vulkan
git pull --ff-only origin build/linux-vulkan
git fetch upstream
git merge upstream/main
```

Commit pending source changes before merging. Resolve any conflicts, then rerun
the codegen, configure and build commands above with a compatible SDK. Check the
native launch before publishing the merged branch:

```sh
./scripts/play_linux.sh
git push origin build/linux-vulkan
```

Merging upstream preserves this branch's compatibility patches without rewriting
published history. Game files, saves, SDK binaries and generated/build outputs
must remain untracked. This branch does not imply an upstream pull request.
