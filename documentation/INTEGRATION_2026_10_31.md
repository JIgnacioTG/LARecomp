# Native Vulkan upstream integration — 2026-10-31

## Scope

Integrated upstream `d1d0578e685b5b71edaefa0ac6a54851a30748c0` (seven commits
since `2f04298`) into local signed base `30cff3e`, on
`integration/upstream-2026-10-31`, in a separate worktree. The tested installation was preserved during compilation. After a successful
259-step build and static validation, this worktree became the sole installed
Lutris version, per the request to retire all previous builds.

Included upstream changes: save-safe shutdown, menu layout, mod-directory
resolution, texture-mod reload/dump, writable-user-folder fallback and the Plume
default. The last is deliberately overridden by `-DLARECOMP_GPU=OFF`.

## Renderer decision

Plume's required `assets/mcla_shaders.v8.pack` and its compatible builder are
still absent from upstream, with no published releases. Upstream issue 8 says
the pack will accompany a release. Compiling Plume is possible (see the retired
trial), but gameplay is not possible without the pack; do not report performance
for that path. This build uses standard Xenos Vulkan with the existing isolated
FidelityFX SDK, not Plume. Real temporal FSR3/FSR4 and frame generation remain
unimplemented; spatial EASU/RCAS fallback is retained.

## Local fixes retained

- Linux platform/build and shared SDL controller-event ownership fixes.
- Writable guest debug-option scratch verification on Linux.
- Counter-disabled SDK readers guarded in timing log and debug overlay.
- Resolve QUIT conflict by retaining Linux SDL_EVENT_QUIT and invoking upstream
  MclaWaitForSaves first; use upstream UI-thread close on Windows and the upstream
  deferred-close fallback when no window exists.

## Build

Codegen with the explicit existing FidelityFX SDK, then configure Clang 20,
Release `-O3 -DNDEBUG`, `-mssse3`, Ninja, and `LARECOMP_GPU=OFF` into
`out/build/linux-updated-release`. All 122 generated translation units (120
translated game files plus init/register) have the optimization flags.

## Runtime isolation and baseline

Independent game files and latest save copied from the tested installation;
cache and user-data paths belong to this worktree. Build config retains the
player's latest quality choices, 2x resolution and 30-FPS limit. Current opponent
high-detail diagnostic option is copied unchanged, not silently removed.

User reports stable gameplay at 30 FPS with stock LOD/shadows; higher targets
can collapse toward 15 FPS. Moving pacing before update did not help. Menu
renders the live world and traffic, so menu slowdown does not exclude traffic
rendering cost. Do not claim a hardware fault or a specific timing bug without
further profiling.

The SDK can serialize `graphics_backend = auto` without quotes, invalidating the
whole TOML file. Prepared config must parse before launch; verify effective
runtime settings, not just on-disk values. This integration does not change the
shared installed SDK serializer.

## Validation

Build and dependency results are recorded in `out/integration/`. Protected hashes
cover the installed executable/config, its save files and Lutris YAML. No game
launch is implied by a successful build; gameplay and saving need a later test.

## Completion and cleanup

- All 259 build steps completed and native ELF linked. `ldd` resolves every
  dependency using the retained SDK install prefix. No Plume target compiled.
- Lutris ID 6 retains its name/slug/artwork, now targets this worktree and its
  `linux-updated-release` build. Explicit arguments keep 30 FPS / 2x, and the
  isolated MangoHud config has no FPS limiter or forced vsync. Other games
  unchanged. No game launch performed after this update.
- Source trees and Git histories retained. Old executable/build trees,
  regenerated sources, old Proton prefix, duplicate extracted game folders and
  experimental SDK compilation caches removed. Required SDK install remains.
  Scoped older game/build Trash entries permanently removed; no unrelated
  Trash entries touched. Save backups and prior capture CSVs retained here.
- Actual free-space change after filesystem sync was approximately 1.45 GiB.
  Apparent duplicate folder sizes were much larger; copied game data used
  reflinks, so apparent sizes must not be reported as freed disk space.
- Launcher quotes known bare graphics_backend enum tokens before loading
  config, preserving a backup of any repaired file. Default build directory
  matches the retained build. Does not alter the shared SDK or other settings.
