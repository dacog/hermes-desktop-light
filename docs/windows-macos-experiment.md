# Experimental Windows and macOS Hermes Light builds

This experiment is maintained **on a separate branch**. It does not alter the Linux release pipeline on `main` and does **not** publish experimental or unsigned installers to stable GitHub Releases.

## Goal

Test whether NousResearch's **existing remote-only Light variant** can be built for Windows and macOS using native GitHub-hosted runners. This branch deliberately uses the upstream `scripts/bundles/desktop.py --commit ... --variant light` interface and avoids editing the application source.

Targets:
- Windows x64: MSIX package, initially unsigned.
- macOS Apple Silicon: DMG and ZIP, initially unsigned / not notarized.

The first checks are compilation and artifact presence only. Successful CI packaging does not prove that Windows accepts an unsigned MSIX or that macOS Gatekeeper allows an unsigned DMG. Production publication will require investigation of signing/notarization and native launch + remote Hermes gateway tests.

Upstream stable desktop downloads are generally **bundled** with the Hermes agent; they do not require a prior install, but ship a local agent runtime. This project specifically targets the **Light** variant for users with existing remote Hermes servers. See the official Hermes installation documentation.

## Status

- [x] Experiment branch created
- [x] Windows x64: **MSIX produced successfully in CI** ([run #38180472615](https://github.com/dacog/hermes-desktop-light/actions/runs/38180472615))
- [x] macOS arm64: **DMG and ZIP produced successfully in CI** ([run #38180472615](https://github.com/dacog/hermes-desktop-light/actions/runs/38180472615))
- [ ] Install and connect to a remote gateway on actual Windows device
- [ ] Install and connect to a remote gateway on actual macOS device
- [ ] Review signing/notarization for user-friendly release distribution

Built artifacts are ephemeral CI artifacts, not release downloads. Credentials (Windows code-signing certificate, Apple Developer ID / notarization) have intentionally not been configured.

## First GitHub Actions test — success

- Upstream pinned to `v0.21.6`, using its exact checkout commit and the official Light variant.
- Windows x64 runner: `windows-2025`; build and `.msix` artifact validation passed.
- macOS Apple Silicon runner: `macos-15`; build and `.dmg`/`.zip` artifact validation passed.
- [Windows unsigned build artifact](https://github.com/dacog/hermes-desktop-light/actions/runs/38180472615#artifacts) (approx. 171 MB ZIP), and [macOS unsigned build artifact](https://github.com/dacog/hermes-desktop-light/actions/runs/38180472615#artifacts) (approx. 273 MB ZIP). CI artifacts expire after seven days.
- Both jobs finished successfully. This validates compilation and file output, **not** installation, launch, notarization, or remote-gateway operation.

### Important installation caveats

Windows MSIX packages normally require trusted code signing before installation; an unsigned MSIX should **not** be presented to ordinary users as a ready-to-install app. macOS unsigned/unnotarized DMGs may be blocked by Gatekeeper. Neither was tested on a physical host. The next phase should prepare an installable test strategy (trusted test cert for Windows, developer signing/notarization for macOS, or a separate portable Windows output) before announcing downloads as supported.
