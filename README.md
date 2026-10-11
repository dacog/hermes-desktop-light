# Hermes Desktop Light — unofficial Ubuntu/Kubuntu APT packages

Community packaging for the **remote-only** Hermes Desktop Light client, built from [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent). Not affiliated with Nous Research.

> **Status:** All four Debian builds passed installation smoke tests in GitHub Actions. GUI launch and remote gateway connectivity have **not** been tested on a real desktop. GitHub Pages must be enabled separately before APT is available.

## Supported targets

| Ubuntu / Kubuntu base | APT suite | Architectures |
| --- | --- | --- |
| 24.04 LTS | noble | amd64, arm64 |
| 26.04 LTS | resolute | amd64, arm64 |

The [project homepage](https://dacog.github.io/hermes-desktop-light/) is generated alongside the signed APT repository, with versioned download links.

The scheduled workflow checks the latest **stable** upstream release twice daily and builds four Debian packages, plus two portable AppImages (amd64 and arm64, compiled on Ubuntu 24.04 for a broad Linux compatibility baseline). Debian packages are checked with `apt-get install` in CI before publication. The remote Hermes gateway runs on a separate device.

## One-time setup

1. In repository **Settings → Pages**, select **GitHub Actions** as the Pages build source.
2. Clone this repo onto a trusted Linux computer with GnuPG installed, and run `bash scripts/generate-signing-key.sh`.
3. **Back up the private key securely**. Set the GitHub Actions repository secret:
   ```bash
   gh secret set APT_GPG_PRIVATE_KEY < signing/apt-private-key.asc
   ```
4. In **Actions**, run **Build Hermes Desktop Light and publish APT**. Confirm all four Debian builds, the two AppImages, the GitHub Release and Pages deployment. If a GitHub Release already exists but APT is not yet published, run with **force=true** after enabling Pages. Otherwise the workflow skips that already-published version.

The signing key is **not** in GitHub; the pipeline cannot sign APT metadata until the secret is configured. GitHub Actions cannot automatically enable Pages with its default GITHUB_TOKEN. If you see a Pages warning, open [Settings → Pages](https://github.com/dacog/hermes-desktop-light/settings/pages) and select **Source: GitHub Actions**. Release assets are uploaded independently of Pages.

## Portable AppImages (no installation)

Download the amd64 or arm64 `.AppImage` from [GitHub Releases](https://github.com/dacog/hermes-desktop-light/releases). On a compatible Linux system:

```bash
chmod +x hermes-desktop-light_*.AppImage
./hermes-desktop-light_*.AppImage
```

AppImages do not use the APT auto-update channel. The older Ubuntu 24.04 build baseline generally improves portability, but compatibility still depends on your Linux environment (including FUSE support). Always test launching and connecting to your remote Hermes gateway.

## Installation through APT

After the first successful Pages deployment:

```bash
set -e
base='https://dacog.github.io/hermes-desktop-light'
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL "$base/hermes-desktop-light.gpg" | sudo tee /etc/apt/keyrings/hermes-desktop-light.gpg >/dev/null
sudo chmod 644 /etc/apt/keyrings/hermes-desktop-light.gpg
codename="$(. /etc/os-release; printf '%s' "$VERSION_CODENAME")"
case "$codename" in noble|resolute) ;; *) echo "Unsupported Ubuntu base: $codename" >&2; exit 1;; esac
arch="$(dpkg --print-architecture)"
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/hermes-desktop-light.gpg] %s %s main\n' "$arch" "$base" "$codename" | sudo tee /etc/apt/sources.list.d/hermes-desktop-light.list
sudo apt update
sudo apt install hermes-desktop-light
```

Then use `sudo apt upgrade` for subsequent updates.

## Workflow

- **Check:** resolve latest stable upstream tag, or manual `upstream_tag`.
- **Build:** check out the upstream release tag, verify its exact commit, prepare upstream Light dependencies plus `deb` packaging tools, and compile with the fixed stable Hermes Light identity using the GitHub Actions build environment. The upstream internal release-claim mechanism is not required for this community build.
- **Package:** normalize the Debian package name to `hermes-desktop-light` and derive a Debian version from the upstream release tag (`0.21.6+ubuntu24.04`, for example), rather than the `0.0.0` source version used for commit builds.
- **Test:** install each Debian package with `apt-get` on its matching runner; assert both portable AppImages are produced.
- **Publish:** generate signed `noble` and `resolute` APT metadata, publish all four Debian packages plus two AppImages through GitHub Releases, and deploy APT to Pages if GitHub Pages is enabled. If Pages is not enabled, the Release remains available and the job reports an explicit warning.

The Linux packaging flow is maintained independently from the disabled upstream Linux release jobs; future upstream changes may require compatibility fixes. This is a community project, not an official upstream installer.

## Security and limitations

The workflow does not include end-to-end GUI-to-gateway testing or vulnerability scanning. The upstream source is checked out by its release tag and verified by the exact commit SHA, but upstream tag cryptographic signatures are not verified. APT signatures authenticate the repository metadata under **your** signing key. Do not commit the contents of `signing/`.

See [upstream Desktop build instructions](https://github.com/NousResearch/hermes-agent/blob/main/apps/desktop/BUILDING.md).
