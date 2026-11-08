#!/bin/bash
# Customizations on top of Bazzite DX: the Hyprland desktop stack.
set -ouex pipefail

# Files from system_files/ (signature policy key and registry config)
cp -avf "/ctx/system_files"/. /

### Hyprland desktop
# Hyprland ecosystem (hyprland, uwsm, hypr* tools, portal) comes from the
# lionheartp/Hyprland COPR, swayosd from erikreider/swayosd. The COPRs are
# only enabled for this build, so the final image ships no extra repos.
# Hyprland requires Fedora's xorg-x11-server-Xwayland, which conflicts with
# Bazzite's pre-release terra-xorg-x11-server-Xwayland. Swap it first.
dnf5 -y swap terra-xorg-x11-server-Xwayland xorg-x11-server-Xwayland

COPRS=(lionheartp/Hyprland erikreider/swayosd)
for copr in "${COPRS[@]}"; do dnf5 -y copr enable "$copr"; done

dnf5 -y install \
    hyprland \
    hyprland-uwsm \
    uwsm \
    hypridle \
    hyprlock \
    hyprpaper \
    hyprpicker \
    xdg-desktop-portal-hyprland \
    waybar \
    swayosd \
    dunst \
    grim \
    slurp

for copr in "${COPRS[@]}"; do dnf5 -y copr disable "$copr"; done

### Image signature verification
# Trust only images from ghcr.io/saharariel/bazzite-hyprland that are signed
# with this repo's cosign key (system_files/etc/pki/containers/saharariel.pub).
POLICY=/etc/containers/policy.json
jq '.transports.docker["ghcr.io/saharariel/bazzite-hyprland"] = [{
        "type": "sigstoreSigned",
        "keyPath": "/etc/pki/containers/saharariel.pub",
        "signedIdentity": {"type": "matchRepository"}
    }]' "$POLICY" > /tmp/policy.json
mv /tmp/policy.json "$POLICY"

### Sanity checks: fail the build rather than ship a broken desktop
rpm -q hyprland hyprland-uwsm uwsm hypridle hyprlock hyprpaper hyprpicker \
    xdg-desktop-portal-hyprland waybar swayosd dunst grim slurp \
    xorg-x11-server-Xwayland
if rpm -q terra-xorg-x11-server-Xwayland; then
    echo "terra Xwayland is still installed" >&2; exit 1
fi
test -f /usr/share/wayland-sessions/hyprland-uwsm.desktop
for repo in /etc/yum.repos.d/*lionheartp* /etc/yum.repos.d/*erikreider*; do
    if [[ -e "$repo" ]] && grep -q '^enabled=1' "$repo"; then
        echo "COPR repo left enabled: $repo" >&2; exit 1
    fi
done
