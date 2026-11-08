# bazzite-hyprland

My desktop OS image: [Bazzite DX](https://github.com/ublue-os/bazzite-dx) stable
plus the Hyprland desktop stack, built on GitHub Actions and signed with cosign.
Nothing is layered on the machine itself, so updates stay atomic and a broken
package set fails here in CI instead of on the PC.

Built from [ublue-os/image-template](https://github.com/ublue-os/image-template).
Configs, CLI tools, fonts and flatpaks live in
[Saharariel/dotfiles](https://github.com/Saharariel/dotfiles).

## What's added on top of Bazzite DX

See [`build_files/build.sh`](build_files/build.sh):

- Hyprland stack from the `lionheartp/Hyprland` COPR: `hyprland`, `hyprland-uwsm`,
  `uwsm`, `hypridle`, `hyprlock`, `hyprpaper`, `hyprpicker`,
  `xdg-desktop-portal-hyprland`
- `swayosd` from the `erikreider/swayosd` COPR
- `waybar`, `dunst`, `grim`, `slurp` from Fedora
- Fedora's `xorg-x11-server-Xwayland` instead of Bazzite's pre-release terra build
- `waybar` 0.16 from Fedora updates-testing until it reaches stable (0.15 can't
  switch workspaces on click with Hyprland 0.57's Lua IPC)
- Signature policy that only trusts this image when signed with
  [`cosign.pub`](cosign.pub)
- A 1G soft cap on core dumps in the user session
  ([`50-core-limit.conf`](system_files/usr/lib/systemd/user.conf.d/50-core-limit.conf)),
  so a crash can never leave huge `core.<pid>` files in `$HOME`

The COPRs are enabled only during the build; the image ships no extra repos.

## How it keeps up with Bazzite

`.github/workflows/build.yml` runs every 2 hours. The `check` job compares the
digest of `ghcr.io/ublue-os/bazzite-dx:stable` with the digest the latest image
was built on (stored in the `io.github.saharariel.base-digest` label), and builds
only when:

- Bazzite published a new `stable`, or
- the last build is 24h old (picks up Hyprland COPR and Fedora updates).

Every build pins the base to that exact digest. On the PC, `ujust update` and the
automatic updater pull this image exactly like they pulled Bazzite. If a build
fails, GitHub emails the repo owner and the PC stays on the last good image.

## Switching a machine to this image

From a Bazzite install:

```bash
sudo rpm-ostree reset      # drop local layers and overrides
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/saharariel/bazzite-hyprland:latest
systemctl reboot
# after the first boot the image's signature policy is installed, so switch
# to the verified transport (same image, no second reboot needed):
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/saharariel/bazzite-hyprland:latest
```

`rpm-ostree rebase` is used rather than `bootc switch`, which refuses to run while the
current deployment still has layered packages.

Then clone the dotfiles and run `./install.sh`.

## Building locally

```bash
just build    # podman build, pinned to the current bazzite-dx:stable digest
```
