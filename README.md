# Hermes Desktop Light — unofficial Ubuntu/Kubuntu APT packages

Community packaging for the **remote-only** Hermes Desktop Light client, built from [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent). Not affiliated with Nous Research.

> **Status:** CI configuration is published, but builds and live gateway connectivity have not yet been verified. Do not install until the first successful release and signed Pages deployment.

## Supported targets

| Ubuntu / Kubuntu base | APT suite | Architectures |
| --- | --- | --- |
| 24.04 LTS | noble | amd64, arm64 |
| 26.04 LTS | resolute | amd64, arm64 |

The scheduled workflow checks the latest **stable** upstream release twice daily and builds four packages. Builds are verified with `apt-get install` before publication. The remote Hermes gateway runs on a separate device.

## One-time setup

1. In repository **Settings → Pages**, select **GitHub Actions** as the Pages build source.
2. Clone this repo onto a trusted Linux computer with GnuPG installed, and run `bash scripts/generate-signing-key.sh`.
3. **Back up the private key securely**. Set the GitHub Actions repository secret:
   ```bash
   gh secret set APT_GPG_PRIVATE_KEY < signing/apt-private-key.asc
   ```
4. In **Actions**, manually run **Build Hermes Desktop Light and publish APT**. Confirm all four builds, package smoke tests, GitHub Release assets, and GitHub Pages deployment succeed.

The signing key is **not** in GitHub; the pipeline cannot publish until the secret is configured.

## Installation

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
- **Test:** install with `apt-get` on each matching runner.
- **Publish:** generate signed `noble` and `resolute` APT metadata, deploy via GitHub Pages, and retain packages in GitHub Releases.

The Linux packaging flow is maintained independently from the disabled upstream Linux release jobs; future upstream changes may require compatibility fixes. This is a community project, not an official upstream installer.

## Security and limitations

The workflow does not include end-to-end GUI-to-gateway testing or vulnerability scanning. The upstream source is checked out by its release tag and verified by the exact commit SHA, but upstream tag cryptographic signatures are not verified. APT signatures authenticate the repository metadata under **your** signing key. Do not commit the contents of `signing/`.

See [upstream Desktop build instructions](https://github.com/NousResearch/hermes-agent/blob/main/apps/desktop/BUILDING.md).
