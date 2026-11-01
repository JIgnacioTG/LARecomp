# Upstream integration — 2026-11-01

- Local base: 15b2839, previous Linux integration.
- Upstream: 6df4900, 29 new non-merge commits since the previous integration.
- Branch/worktree: integration/upstream-2026-11-01 / LARecomp-update-20261101.
- Standard Xenos Vulkan retained with LARECOMP_GPU=OFF; no usable Plume shader
  pack has been supplied. Existing installed FidelityFX/counters-disabled SDK is
  pinned explicitly and remains unchanged.
- Frame-pump wake and audio-priority changes upstream are Windows-only and are
  not claimed as Linux performance improvements. Plume-specific optimizations
  are not used by this standard-Vulkan build.
- Retained shared SDL ownership fix, Linux writable scratch fix, counter-reader
  guards, Linux quit/save handling and launcher config-enum repair.
- Upstream's fixed 18-row menu capacity conflicts with our table-derived
  capacity; retained our equivalent table-derived capacity fix.
- Independent copied game data, latest user data and cache paths. All previous
  graphics and frame-cap choices retained; source had 30-FPS cap and 2x scale.
- Default MangoHud remains uncapped; LSFG remains disabled for this title.
- No launch is authorized for this update, even a --help invocation. Validation
  is file format, compile flags, linked libraries, hash comparison and Lutris
  launch-script generation only. Gameplay is explicitly untested.

Build logs and protected-install hashes live under out/integration/. After
successful build, the existing Lutris entry is repointed without changing its
identity/artwork. Prior save data and tiny config backups are preserved.

## Additional Linux guard

The new DualSense trigger implementation uses HANDLE/SetupDi/WriteFile APIs
outside its Windows include guard. Compile the HID implementation only on
Windows and retain no-op lifecycle/codegen hook symbols elsewhere. Hide its
Windows-only menu row in the Linux build rather than advertising a missing
backend. No Linux DualSense trigger support is claimed. Xbox/shared SDL input
behavior is unchanged.

## Link and installation validation

The new pump-wake hooks are installed by the manifest on Linux too, but the
upstream implementations are Windows-only. Added non-Windows hook symbols that
leave the original ring wait and Sleep path untouched. Final targeted build
linked successfully. All dependencies resolve through the retained SDK install.
Both existing Lutris entries now reference the updated paths and their launch
scripts/artwork resolve. LARecomp current save matches its copied baseline; no
game was executed. DriveClub 0.4.0 official optimized Windows archive checksum
passed and its existing GE-Proton prefix, launcher.ini and data/user were kept;
no source rebuild of that prebuilt release was required.
