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
- [ ] Windows x64: package produced
- [ ] macOS arm64: package produced
- [ ] Install and connect to a remote gateway on actual Windows device
- [ ] Install and connect to a remote gateway on actual macOS device
- [ ] Review signing/notarization for user-friendly release distribution

Built artifacts are ephemeral CI artifacts, not release downloads. Credentials (Windows code-signing certificate, Apple Developer ID / notarization) have intentionally not been configured.
