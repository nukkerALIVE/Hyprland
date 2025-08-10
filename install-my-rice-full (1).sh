#!/usr/bin/env bash
# install-my-rice-full.sh
# Maxed-out Hyprland rice installer for Arch/EndeavourOS (one-shot).
# WARNING: This script WILL remove KDE Plasma and install packages. You told me you are sure.
# Run on your EndeavourOS machine after pushing to GitHub and pulling, or run directly via:
#   bash <(curl -s https://raw.githubusercontent.com/<you>/<repo>/main/install-my-rice-full.sh)
#
set -euo pipefail
IFS=$'\n\t'

# -----------------------
# Configuration options
# -----------------------
REMOVE_KDE=true        # already confirmed by user
BACKUP_DIR="$HOME/dotfiles-backup-$(date +%F-%H%M%S)"
WALL_SRC_DIR="$HOME/.config/wallpaper"   # where wallpapers will be stored
REPO_BASE="$(cd "$(dirname "$0")" && pwd)"

# Packages to install (only missing ones are installed)
PKGS=(
  hyprland waybar kitty mpvpaper ffmpeg pywal imagemagick
  networkmanager network-manager-applet bluez bluez-utils blueman
  pipewire pipewire-pulse wireplumber
  rofi btop grim slurp wl-clipboard jq playerctl dunst
  wlroots-git # optional, many systems already have required libs
)

echo "==> This script will configure Hyprland + Waybar rice (maxed-out)"
echo "    Backups (if any) will be put in: $BACKUP_DIR"
sleep 2

# -----------------------
# Remove KDE Plasma (destructive)
# -----------------------
if $REMOVE_KDE; then
  echo "==> Removing KDE Plasma packages (this is destructive) ..."
  sudo pacman -Rns --noconfirm plasma-meta kde-applications || echo "Some KDE packages may not be installed or removal failed."
fi

# -----------------------
# Update + install packages (only missing ones)
# -----------------------
echo "==> Checking and installing packages (missing only)..."
MISSING=()
for p in "${PKGS[@]}"; do
  if ! pacman -Qq "$p" &>/dev/null; then
    MISSING+=("$p")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "==> Installing: ${MISSING[*]}"
  sudo pacman -Syu --noconfirm --needed "${MISSING[@]}"
else
  echo "==> All required packages already installed."
fi

# -----------------------
# Enable services
# -----------------------
echo "==> Enabling NetworkManager and bluetooth services..."
sudo systemctl enable --now NetworkManager || echo "Failed to enable NetworkManager"
sudo systemctl enable --now bluetooth || echo "Failed to enable bluetooth"

# -----------------------
# Backup existing config dirs
# -----------------------
echo "==> Backing up existing configs to $BACKUP_DIR (if present)"
mkdir -p "$BACKUP_DIR"
for d in hypr waybar kitty rofi wallpaper swww; do
  if [ -d "$HOME/.config/$d" ]; then
    mv "$HOME/.config/$d" "$BACKUP_DIR/"
    echo "  Moved existing ~/.config/$d -> $BACKUP_DIR/"
  fi
done

# -----------------------
# Create config directories and files
# -----------------------
echo "==> Creating new config structure..."
mkdir -p "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/kitty" "$HOME/.config/rofi" "$HOME/.config/scripts" "$WALL_SRC_DIR"

# --- hyprland.conf (frosty glass basics + autostart will use autostart.conf) ---
cat > "$HOME/.config/hypr/hyprland.conf" <<'HYPR'
# Minimal Hyprland config with frosted glass-friendly settings
general {
  # set your preferred options here
  monitorrule = HDMIA-1, 2560x1440@0x0, preferred=1
}

decoration {
  rounding = 14
  blur = 1
  blur_size = 14
  blur_passes = 3
}

# gaps so floating bars appear like macOS floating panels (adjust per-display)
gaps_in = 20
gaps_out = 20

# example keybinds
bind = SUPER+ENTER, exec, kitty
bind = SUPER+d, exec, rofi -show drun
bind = SUPER+Shift+q, killactive

# Use autostart.conf for apps
HYPR

# --- autostart.conf to start Waybar instances, nm-applet, bluetooth, dunst, wallpaper ---
mkdir -p "$HOME/.config/hypr"
cat > "$HOME/.config/hypr/autostart.conf" <<'AUTO'
# Autostart entries added by install-my-rice-full.sh
# start tray / applets
exec-once = nm-applet &
exec-once = blueman-applet &
exec-once = dunst &
# start three Waybar instances (top, right, bottom)
exec-once = waybar -c ~/.config/waybar/top.json &
exec-once = waybar -c ~/.config/waybar/right.json &
exec-once = waybar -c ~/.config/waybar/bottom.json &
# start wallpaper handler
exec-once = bash ~/.config/scripts/set-wallpaper.sh &
AUTO

# -----------------------
# Waybar configs: top, right, bottom, and style
# -----------------------
cat > "$HOME/.config/waybar/style.css" <<'CSS'
* {
  background: rgba(18, 18, 20, 0.45);
  color: #e6eef7;
  border-radius: 12px;
  padding: 6px;
}
#waybar {
  box-shadow: 0 10px 30px rgba(0,0,0,0.5);
}
CSS

cat > "$HOME/.config/waybar/top.json" <<'TOP'
{
  "layer": "top",
  "position": "top",
  "margin": 18,
  "modules-left": ["sway/workspaces"],
  "modules-center": ["cpu", "memory", "temperature", "weather"],
  "modules-right": ["battery", "clock"]
}
TOP

cat > "$HOME/.config/waybar/right.json" <<'RIGHT'
{
  "layer": "top",
  "position": "right",
  "orientation": "vertical",
  "width": 220,
  "modules-left": [],
  "modules-center": ["network", "bluetooth", "pulseaudio"],
  "modules-right": []
}
RIGHT

cat > "$HOME/.config/waybar/bottom.json" <<'BOTTOM'
{
  "layer": "top",
  "position": "bottom",
  "margin": 18,
  "modules-left": ["sway/workspaces"],
  "modules-center": ["custom/taskbar"],
  "modules-right": ["tray"]
}
BOTTOM

# -----------------------
# Waybar custom modules (simple taskbar placeholder)
# -----------------------
mkdir -p "$HOME/.config/waybar/scripts"
cat > "$HOME/.config/waybar/scripts/taskbar.sh" <<'TASK'
#!/usr/bin/env bash
# Very small taskbar placeholder: lists active windows (uses hyprlandctl if available)
if command -v hyprctl &>/dev/null; then
  hyprctl activewindow | sed -n '1p'
else
  echo "Apps"
fi
TASK
chmod +x "$HOME/.config/waybar/scripts/taskbar.sh"

# -----------------------
# Kitty config (glass terminal)
# -----------------------
cat > "$HOME/.config/kitty/kitty.conf" <<'KITTY'
background_opacity 0.85
allow_remote_control yes
title_format {title} - {cwd}
kitten ssh -o StrictHostKeyChecking=no
KITTY

# -----------------------
# Rofi config (theme will be affected by pywal colors)
# -----------------------
cat > "$HOME/.config/rofi/config.rasi" <<'ROFI'
configuration {
  modi: "drun,run,window";
  show-icons: true;
  theme: "gruvbox";
}
ROFI

# -----------------------
# dunst config (notifications translucent)
# -----------------------
mkdir -p "$HOME/.config/dunst"
cat > "$HOME/.config/dunst/dunstrc" <<'DUNST'
[global]
  transparency = 10
  frame_width = 2
DUNST

# -----------------------
# Wallpaper script: convert GIFs -> webm and run mpvpaper; run pywal for colors
# -----------------------
mkdir -p "$HOME/.config/scripts"
cat > "$HOME/.config/scripts/set-wallpaper.sh" <<'WALL'
#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="$HOME/.config/wallpaper"
# ensure directory exists
mkdir -p "$WALL_DIR"

# prefer first webm, else convert any gif to webm
file=""
shopt -s nullglob
for f in "$WALL_DIR"/*.{webm,mp4}; do file="$f"; break; done
if [ -z "$file" ]; then
  for g in "$WALL_DIR"/*.{gif,GIF}; do
    base="$(basename "$g" | sed 's/\\.[Gg][Ii][Ff]$//')"
    out="$WALL_DIR/${base}.webm"
    echo "Converting $g -> $out (this may take a moment)"
    ffmpeg -y -i "$g" -c:v libvpx-vp9 -b:v 0 -crf 30 -an -pix_fmt yuva420p -loop 0 "$out" </dev/null >/dev/null 2>&1 || \
      ffmpeg -y -i "$g" -c:v libx264 -pix_fmt yuv420p "$out" </dev/null >/dev/null 2>&1 || true
    file="$out"
    break
  done
fi

if [ -z "$file" ]; then
  echo "No webm/mp4/gif wallpaper found in $WALL_DIR"
  exit 1
fi

# kill any existing mpvpaper instance
pkill mpvpaper || true

# start mpvpaper on all monitors
mpvpaper '*' "$file" --loop --mute --no-audio --pause=no &

# run pywal to extract colors (grab a frame if it's a video)
if [[ "$file" =~ \\.webm$ || "$file" =~ \\.mp4$ ]]; then
  tmp="$HOME/.cache/wal_frame.png"
  ffmpeg -y -ss 0.5 -i "$file" -vframes 1 "$tmp" </dev/null >/dev/null 2>&1 || true
  if [ -f "$tmp" ]; then
    wal -i "$tmp"
  else
    wal -i "$file"
  fi
else
  wal -i "$file"
fi
WALL
chmod +x "$HOME/.config/scripts/set-wallpaper.sh"

# -----------------------
# Place a couple of helpful scripts (reload hypr, restart mpvpaper)
# -----------------------
cat > "$HOME/.config/scripts/reload-hypr.sh" <<'RH'\n#!/usr/bin/env bash\n# Reload hyprland config\nhyprctl reload\nRH
chmod +x "$HOME/.config/scripts/reload-hypr.sh"

# -----------------------
# Copy user's wallpapers from repo (if script located inside repo with config/wallpaper)
# If user ran script from inside a cloned repo, attempt to copy wallpapers automatically.
# -----------------------
if [ -d "$REPO_BASE/config/wallpaper" ]; then
  echo "==> Copying wallpapers from repo -> $WALL_SRC_DIR"
  cp -r "$REPO_BASE/config/wallpaper/"* "$WALL_SRC_DIR/" 2>/dev/null || true
fi

# -----------------------
# Finalization
# -----------------------
echo "==> Finished creating configs and scripts."
echo "==> Running set-wallpaper.sh to start wallpaper and pywal (if possible)"
bash "$HOME/.config/scripts/set-wallpaper.sh" || echo "Wallpaper start failed - check ~/.config/scripts/set-wallpaper.sh"

echo "==> You should now log out and choose the Hyprland seat/session, or reboot."
echo "==> If you kept KDE and want to keep it while testing, you can keep using SDDM but pick Hyprland session."
echo
echo "==> Tip: If Waybar doesn't show, run: waybar -c ~/.config/waybar/top.json &"
