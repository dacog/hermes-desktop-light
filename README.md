# Hermes Desktop Light for Linux

**Run the Hermes desktop client on your laptop without installing the complete Hermes Agent locally.**

Unofficial, community-maintained Linux packages for the **remote-only Hermes Light** variant from [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent). This project builds the upstream desktop application in GitHub Actions and distributes it as portable **AppImages** and native **Ubuntu/Kubuntu `.deb` packages**, including a signed APT repository for normal system updates.

**[Project website and APT instructions](https://dacog.github.io/hermes-desktop-light/)** · **[Download latest release](https://github.com/dacog/hermes-desktop-light/releases/latest)** · **[Build workflow](.github/workflows/release.yml)**

> **Independent packaging, not a fork of Hermes Desktop.** We do **not patch or modify the tracked Hermes application source code**. Each build checks out a published upstream release from GitHub and uses its existing Light variant. The workflow makes packaging-specific adjustments to the build environment, temporary third-party packaging tools, and Debian package metadata, but does not change the app's original source files. This repository is **not affiliated with or endorsed by Nous Research**.

## Why this project exists

I use several computers and laptops, while my Hermes Agent runs on a **separate, remote server**. I wanted to open the Hermes desktop interface on any of those devices and connect to the existing agent—not install and operate another full copy of Hermes on every machine.

I first tried the [official Hermes installer](https://github.com/NousResearch/hermes-agent) on Kubuntu:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

In my case, the installation became stuck around the **`git clone`** step. More importantly, a full local installation was not what I wanted in the first place: the agent was already running remotely. Looking for a prebuilt Linux package of the upstream **remote-only Hermes Light** desktop variant, I did not find one that matched this use case at the time.

So I created this small distribution project: **build the upstream Light client once in CI, download it on multiple devices, and leave Hermes Agent running on the server**. No per-laptop cloning, Python environment, or local Hermes Agent installation should be required to use the packaged Light client.

The project solves a distribution problem, **not** a problem that requires a modified desktop application. The earlier installer experience is a personal report, not a claim that the upstream installer fails for everyone.

## What gets packaged—and what does not

- **Included:** the upstream Electron desktop application built with `--variant light`, the remote-only variant designed to connect to an existing Hermes service.
- **Not included:** a second local Hermes Agent installation, its Python runtime, or a local agent environment to manage.
- **Not changed:** Hermes application source files, features, UI code, or upstream release contents.
- **Adapted for Linux distribution:** CI build arguments and tools, package naming/version metadata, native Linux launch integration, and the signed APT repository.

The resulting packages are based on a specific upstream Git tag and exact checkout commit. The workflow applies compatibility fixes **only while preparing and packaging** the application; these do not create or maintain an independent fork of Hermes itself.

## Current compatibility and testing

| Format | Platform | Architecture | Verification |
| --- | --- | --- | --- |
| AppImage | **Kubuntu 26.04** | AMD64 | **Launched successfully and connected to a remote Hermes backend** (October 2026, user-tested) |
| AppImage | Other compatible Linux distributions | AMD64, ARM64 | Builds in CI; graphical operation not yet confirmed |
| `.deb` | Ubuntu/Kubuntu 24.04 (noble) | AMD64, ARM64 | Builds and installs successfully in GitHub Actions |
| `.deb` | Ubuntu/Kubuntu 26.04 (resolute) | AMD64, ARM64 | Builds and installs successfully in GitHub Actions; **manual desktop test pending** |

**Verified on a real device:** on Kubuntu 26.04 AMD64, the AppImage **opens and successfully connects to an existing remote Hermes backend**. The `.deb` packages have passed installation smoke tests in CI, but are **still awaiting manual GUI testing**.

The AppImages are compiled on Ubuntu 24.04 to provide a relatively conservative Linux baseline; this does not guarantee compatibility with every distribution or desktop environment.

## Download and run

### Option 1: AppImage (portable; no installation)

Download the appropriate `.AppImage` for your CPU from [GitHub Releases](https://github.com/dacog/hermes-desktop-light/releases/latest).

```bash
chmod +x hermes-desktop-light_*.AppImage
./hermes-desktop-light_*.AppImage
```

The AppImage has been opened and **connected successfully to a remote Hermes backend on Kubuntu 26.04 (AMD64)**. Depending on the distribution, AppImage execution can require FUSE-related compatibility packages. AppImages do **not** receive APT updates or necessarily create an application menu shortcut automatically.

### Option 2: Native `.deb` via APT (Ubuntu/Kubuntu)

Install from the [signed APT repository](https://dacog.github.io/hermes-desktop-light/) for regular system updates:

```bash
set -e
base='https://dacog.github.io/hermes-desktop-light'
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL "$base/hermes-desktop-light.gpg" | sudo tee /etc/apt/keyrings/hermes-desktop-light.gpg >/dev/null
sudo chmod 644 /etc/apt/keyrings/hermes-desktop-light.gpg

codename="$(. /etc/os-release; printf '%s' "$VERSION_CODENAME")"
case "$codename" in
  noble|resolute) ;;
  *) echo "Unsupported Ubuntu base: $codename" >&2; exit 1 ;;
esac
arch="$(dpkg --print-architecture)"

printf 'deb [arch=%s signed-by=/etc/apt/keyrings/hermes-desktop-light.gpg] %s %s main\n' \
  "$arch" "$base" "$codename" | sudo tee /etc/apt/sources.list.d/hermes-desktop-light.list

sudo apt update
sudo apt install hermes-desktop-light
```

Once installed, look for **Hermes Light** in the application menu. Updates are handled by your usual `sudo apt upgrade`. Alternatively, download the matching `.deb` from [Releases](https://github.com/dacog/hermes-desktop-light/releases/latest).

## Automatic upstream release tracking and updates

**This repository automatically tracks new stable Hermes Agent releases.** GitHub Actions checks the official [NousResearch/hermes-agent releases](https://github.com/NousResearch/hermes-agent/releases) **twice a day**, at **05:17 and 17:17 UTC**, and compares the latest stable upstream tag against the releases already published by this project.

When a new stable tag appears, the workflow automatically:

1. Checks out that exact upstream version and builds the unmodified **Hermes Light** desktop client for the supported Linux targets.
2. Runs Debian installation smoke tests, then publishes four `.deb` packages and two AppImages, plus SHA-256 checksums, to this project's GitHub Releases.
3. Regenerates the signed APT repository and GitHub Pages downloads page.

**No manual rebuild or release upload is normally needed.** If a version is already published, the workflow skips it; scheduled GitHub Actions runs may occasionally be delayed, and a failed build or deployment requires attention.

**How updates reach your devices:** on Ubuntu/Kubuntu, installing from the signed APT repository means newly published versions are available through your usual `sudo apt update && sudo apt upgrade` (or your graphical system updater). **AppImages do not automatically update on your devices**; download a newer AppImage from Releases when one is available. The repository automation publishes updated binaries, but it does **not** automatically modify the tracked Hermes source files or install anything on your devices.

Website-only changes are handled by a [separate GitHub Pages workflow](.github/workflows/pages.yml), which reuses already published packages instead of recompiling Hermes.

## How the builds work

The [GitHub Actions workflow](.github/workflows/release.yml):

1. Checks for the latest stable NousResearch Hermes release **twice daily at 05:17 and 17:17 UTC** (scheduled GitHub Actions runs may be delayed), or accepts a manually specified upstream tag. When no new stable release is available, the build and publication jobs are skipped.
2. Checks out that exact upstream release and compiles the official **Light** desktop variant—no locally installed Hermes Agent is required.
3. Builds **four `.deb` packages**: Ubuntu 24.04 and 26.04, each for AMD64 and ARM64.
4. Builds **two portable AppImages** (AMD64 and ARM64), using Ubuntu 24.04 runners.
5. Tests the installation of each `.deb` with APT inside its matching GitHub Actions runner.
6. Publishes all six binaries and SHA-256 checksums to [GitHub Releases](https://github.com/dacog/hermes-desktop-light/releases), and deploys the signed APT repository and download homepage through GitHub Pages.

The separate [Pages deployment workflow](.github/workflows/pages.yml) updates the homepage and signed APT metadata **without rebuilding Hermes**. It downloads the last published release, verifies its checksums, re-generates the repository metadata and site, and deploys it. This also runs automatically when the homepage template or APT publishing script changes.

Linux release builds are not currently part of the upstream project's regular release matrix. This repository fills that gap independently. The temporary packaging adaptations, stable application identity, and Debian package name are maintained **here**, without submitting modified Hermes app source as our own.

### For maintainers: APT signing

GitHub Pages must use **Settings → Pages → Source: GitHub Actions**. On a trusted local machine with GnuPG installed, generate and back up the signing key:

```bash
bash scripts/generate-signing-key.sh
gh secret set APT_GPG_PRIVATE_KEY < signing/apt-private-key.asc
```

The private key belongs in a secure, separate backup—not in Git. The entire `signing/` directory is ignored by `.gitignore`. The secret is used only by GitHub Actions to sign APT metadata.

Releases already published are skipped by default. To **rebuild binaries**, use **Actions → Build Hermes Desktop Light and publish APT → Run workflow** with `force=true`. To **refresh only GitHub Pages / APT metadata**, use **Actions → Deploy Hermes Desktop Light Pages → Run workflow** instead; it reuses the already published release assets and does not recompile the application.

## Scope and possible future distributions

**For now, this project deliberately focuses on Ubuntu/Kubuntu.** Before broadening distribution support, the goal is to finish desktop/gateway testing and verify that APT updates behave correctly on actual machines.

Fedora (`.rpm`) and Arch Linux packages are possible future additions, but not currently supported. There are also related community efforts worth knowing about:

- [jabla/hermes-agent-desktop-bin](https://github.com/jabla/hermes-agent-desktop-bin): an existing **Arch/AUR** desktop package, built using a different approach and patches; useful to review before duplicating Arch packaging work.
- [fdfretes/hermes-desktop-linux-arm64](https://github.com/fdfretes/hermes-desktop-linux-arm64): a separate Linux ARM64 desktop distribution based on another Hermes Desktop wrapper, designed around a bundled local runtime, rather than this upstream remote-only Light packaging.

These projects are related but **not interchangeable**. Their existence is a good reason to collaborate or reuse established distro packaging conventions rather than assume no other Linux work exists.

## Credits and disclaimer

**Initiated and maintained by Diego Carrasco; co-created through an iterative collaboration with [ChatGPT](https://chatgpt.com) (OpenAI).** ChatGPT assisted with the packaging design, GitHub Actions workflows, debugging, and documentation. Diego is responsible for the repository, releases, signing key, and testing decisions.

**Hermes Agent and Hermes Desktop are created by [Nous Research](https://github.com/NousResearch/hermes-agent)**. All credit for the original application belongs to its upstream authors. This is an independent packaging and distribution project, with no affiliation or endorsement implied from Nous Research or OpenAI.

## Security and limitations

Builds consume the exact upstream release checkout and use an independently maintained GitHub Actions workflow. The project does not currently verify upstream cryptographic tag signatures, provide a third-party security audit, or test every desktop environment. APT repository metadata is signed with the maintainer's GPG key. Review releases and provenance before installing software from any third-party package repository.

See [upstream desktop build documentation](https://github.com/NousResearch/hermes-agent/blob/main/apps/desktop/BUILDING.md) for the official application build contract.
