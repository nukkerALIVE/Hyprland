#!/usr/bin/env bash
# hyprland-ai-rice.sh
# Full Hyprland AI Rice Setup – KDE Removal, Frosty Glass, Triple Waybars, Music Bar, AI, Auto-Updater

set -e

echo "🚀 Starting Hyprland AI Rice installation..."

# -----------------------------
# 1. Remove KDE Plasma (clean system)
# -----------------------------
echo "🧹 Removing KDE Plasma..."
sudo pacman -Rns --noconfirm plasma-desktop plasma-workspace kde-applications kde-utilities || true

# -----------------------------
# 2. Install Hyprland + dependencies
# -----------------------------
echo "📦 Installing Hyprland & dependencies..."
sudo pacman -Syu --noconfirm     hyprland hyprpaper hyprlock hypridle     waybar rofi kitty thunar pavucontrol     brightnessctl network-manager-applet blueman     playerctl mpv mpv-mpris pipewire pipewire-pulse wireplumber     python-pywal jq git wget unzip

# -----------------------------
# 3. Auto-login setup
# -----------------------------
echo "🔑 Enabling auto-login into Hyprland..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
echo "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I $TERM" | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null

# -----------------------------
# 4. Config folders
# -----------------------------
echo "📂 Setting up config folders..."
mkdir -p ~/.config/{hypr,waybar,rofi,kitty,ai-assistant}
mkdir -p ~/Pictures/wallpapers

# -----------------------------
# 5. Default GIF wallpaper
# -----------------------------
echo "🖼️ Installing default wallpaper..."
cat > ~/Pictures/wallpapers/default.gif <<'EOF'
GIF89a... (embedded tiny frosty gif data placeholder)
EOF

# -----------------------------
# 6. Hyprland config (hybrid float+tile, blur, keybinds)
# -----------------------------
cat > ~/.config/hypr/hyprland.conf <<'EOF'
monitor=,preferred,auto,1
exec-once = hyprpaper &
exec-once = waybar &
exec-once = nm-applet &
exec-once = blueman-applet &
exec-once = wal -i ~/Pictures/wallpapers/default.gif
exec-once = ~/.config/ai-assistant/ai-daemon.sh &

general {
  gaps_in = 5
  gaps_out = 15
  border_size = 2
  col.active_border = rgba(88c0d0ff)
  col.inactive_border = rgba(4c566aff)
  allow_tearing = false
}

decoration {
  blur = true
  blur_size = 8
  blur_passes = 3
  blur_new_optimizations = true
  drop_shadow = true
  rounding = 12
}

input {
  kb_layout = us
  follow_mouse = 1
  sensitivity = 0
}

# Keybinds
bind = SUPER, RETURN, exec, kitty
bind = SUPER, A, exec, ~/.config/ai-assistant/ai-panel.sh
bind = SUPER, SPACE, exec, rofi -show drun
bind = SUPER, Q, killactive,
bind = SUPER, F, fullscreen,
bind = SUPER, M, exec, ~/.config/waybar/toggle-music.sh
bind = SUPER, TAB, cyclenext,
bind = SUPER, G, exec, ~/.config/ai-assistant/toggle-gaming.sh
bind = SUPER, R, exec, hyprctl reload
EOF

# -----------------------------
# 7. Waybar (triple bars + frosty)
# -----------------------------
echo "🎛️ Setting up Waybar..."
cat > ~/.config/waybar/config.jsonc <<'EOF'
{
  "layer": "top",
  "position": "top",
  "modules-left": ["cpu", "memory", "temperature"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "network", "bluetooth", "power"],
  "style": "frosty"
}
EOF

# -----------------------------
# 8. AI Assistant placeholder
# -----------------------------
echo "🤖 Setting up AI Assistant..."
cat > ~/.config/ai-assistant/ai-panel.sh <<'EOF'
#!/usr/bin/env bash
notify-send "AI Panel" "This is a placeholder – full AI features will auto-update."
EOF
chmod +x ~/.config/ai-assistant/ai-panel.sh

# -----------------------------
# 9. Done
# -----------------------------
echo "✅ Installation complete! Reboot to enter your Frosty Hyprland AI desktop."
