#!/bin/bash

# Stop script on errors
set -e

echo "=== 1. Installation ==="

echo "--> Configuring Mirror Sources (USTC)..."
# backup
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
# fix
sudo tee /etc/apt/sources.list << 'EOF'
deb https://mirrors.ustc.edu.cn/debian/ trixie main
deb https://mirrors.ustc.edu.cn/debian/ trixie-updates main
deb https://mirrors.ustc.edu.cn/debian-security trixie-security main
EOF
# update
sudo apt update

echo "--> Installing Packages..."
sudo apt install -y labwc waybar foot fuzzel thunar swaybg lxpolkit mako-notifier brightnessctl pavucontrol nm-tray qt6-wayland xdg-desktop-portal-wlr xwayland \
grim slurp wl-clipboard swaylock cliphist \
fonts-noto-cjk fonts-font-awesome fcitx5 fcitx5-chinese-addons \
libnotify-bin network-manager-gnome curl wget git \
flatpak adb fastboot # for personal

echo "=== 2. Configuration ==="

echo "--> Setting up Basic Config..."
mkdir -p ~/.config/labwc && cp -r /usr/share/doc/labwc/examples/* ~/.config/labwc/ || echo "no file , check install"

echo "--> Configuring Autostart..."
cat > ~/.config/labwc/autostart <<'EOF'
#!/bin/sh

LOG="$HOME/.local/state/labwc-autostart.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1

# import environment vars into systemd user environment
dbus-update-activation-environment --systemd --all || echo "Failed to update env for systemd"

# ---- PolicyKit Agent ----
# If you have policykit-1-gnome installed, this session handles authentication dialogs
if [ -x /usr/lib/polkit-1-gnome/polkit-gnome-authentication-agent-1 ]; then
  /usr/lib/polkit-1-gnome/polkit-gnome-authentication-agent-1 &
fi


swaybg -c "#2E3440" &
fcitx5 -d --replace &
mako &
nm-tray &
waybar &
wl-paste --watch cliphist store &

# ---- xdg-desktop-portal ----
# /usr/lib/xdg-desktop-portal &
echo "autostart finished at $(date)"
EOF

chmod +x ~/.config/labwc/autostart

echo "--> Adding user to 'video' group..."
sudo usermod -aG video $USER

echo "--> Configuring Right-Click Menu (menu.xml)..."
cat > ~/.config/labwc/menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu>
  <menu id="apps" label="Applications">
    <item label="Terminal (Foot)">
      <action name="Execute"><command>foot</command></action>
    </item>
    <item label="Files (Thunar)">
      <action name="Execute"><command>thunar</command></action>
    </item>
  </menu>

  <menu id="system" label="System">
    <item label="Network (nm-tray)">
      <action name="Execute"><command>nm-tray</command></action>
    </item>
    <item label="Volume (pavucontrol)">
      <action name="Execute"><command>pavucontrol</command></action>
    </item>
    <separator />
    <item label="Screenshot (Selection)">
      <action name="Execute">
        <command>sh -c 'mkdir -p ~/Pictures && grim -g "$(slurp)" ~/Pictures/$(date +%s).png && notify-send "Screenshot saved" || notify-send "Screenshot failed"'</command>
      </action>
    </item>

  <separator />

  <menu id="power" label="Power Options">
    <item label="Lock Screen">
      <action name="Execute"><command>swaylock -c 000000</command></action>
    </item>
    <item label="Exit Labwc">
      <action name="Exit" />
    </item>
    <item label="Reboot">
      <action name="Execute"><command>systemctl reboot</command></action>
    </item>
    <item label="Shutdown">
      <action name="Execute"><command>systemctl poweroff</command></action>
    </item>
  </menu>

</openbox_menu>
EOF

echo "--> Configuring Environment Variables..."
cat > ~/.config/labwc/environment << 'EOF'
# ---- Input Method: Fcitx5 ----
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS="@im=fcitx"

# other IM modules (optional)
export SDL_IM_MODULE=fcitx5

# ---- Desktop / Wayland session ----
export XDG_CURRENT_DESKTOP=labwc
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=labwc

# toolkit backends (Wayland first, fallback to X11)
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM=wayland

# Firefox Wayland support
export MOZ_ENABLE_WAYLAND=1

# Java AWT nonreparenting workaround
export _JAVA_AWT_WM_NONREPARENTING=1
EOF

echo "--> Configuring Shortcuts and Theme (rc.xml)..."
cat > ~/.config/labwc/rc.xml << 'EOF'
<?xml version="1.0"?>
<labwc_config>

  <!-- Workspace count -->
  <desktops number="4"/>

  <!-- Theme (optional) -->
  <theme>
    <cornerRadius>6</cornerRadius>
    <titlebar>
      <layout>icon:iconify,max,close</layout>
      <showTitle>yes</showTitle>
    </titlebar>
  </theme>

  <placement>
    <policy>Cascade</policy>
    <cascadeOffset x="30" y="20"/>
  </placement>

  <keyboard>
    <!-- Keep default shortcuts -->
    <default/>

    <!-- Launch terminal -->
    <keybind key="W-Return">
      <action name="Execute" command="foot"/>
    </keybind>

    <!-- Launch Launcher -->
    <keybind key="W-d">
      <action name="Execute" command="fuzzel"/>
    </keybind>

    <!-- Lock screen (requires swaylock or swaylock-effects) -->
    <keybind key="W-l">
      <action name="Execute" command="swaylock -c 000000"/>
    </keybind>

    <!-- Close current window -->
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>

    <!-- Maximize/Unmaximize -->
    <keybind key="W-a">
      <action name="ToggleMaximize"/>
    </keybind>

    <!-- Fullscreen -->
    <keybind key="W-f">
      <action name="ToggleFullscreen"/>
    </keybind>

    <!-- Workspace switching -->
    <keybind key="W-1"><action name="GoToDesktop" to="1"/></keybind>
    <keybind key="W-2"><action name="GoToDesktop" to="2"/></keybind>
    <keybind key="W-3"><action name="GoToDesktop" to="3"/></keybind>
    <keybind key="W-4"><action name="GoToDesktop" to="4"/></keybind>

    <!-- Volume control -->
    <keybind key="XF86_AudioLowerVolume">
      <action name="Execute" command="pactl set-sink-volume @DEFAULT_SINK@ -5%"/>
    </keybind>
    <keybind key="XF86_AudioRaiseVolume">
      <action name="Execute" command="pactl set-sink-volume @DEFAULT_SINK@ +5%"/>
    </keybind>
    <keybind key="XF86_AudioMute">
      <action name="Execute" command="pactl set-sink-mute @DEFAULT_SINK@ toggle"/>
    </keybind>

    <!-- Brightness control -->
    <keybind key="XF86_MonBrightnessDown">
      <action name="Execute" command="brightnessctl set 10%-"/>
    </keybind>
    <keybind key="XF86_MonBrightnessUp">
      <action name="Execute" command="brightnessctl set +10%"/>
    </keybind>

    <!-- Screenshot: select area -->
    <keybind key="Print">
      <action name="Execute" command="sh -c 'mkdir -p ~/Pictures &amp;&amp; slurp | grim ~/Pictures/screenshot-$(date +%s).png'"/>
    </keybind>

    <!-- Fullscreen screenshot -->
    <keybind key="W-Print">
      <action name="Execute" command="sh -c 'mkdir -p ~/Pictures &amp;&amp; grim ~/Pictures/screenshot-$(date +%s).png'"/>
    </keybind>
  </keyboard>

  <mouse>
    <context name="Frame">
      <mousebind button="Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="Right" action="Drag">
        <action name="Resize"/>
      </mousebind>
    </context>

    <context name="Root">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"/>
      </mousebind>
    </context>
  </mouse>

  <windowRules>
    <!-- Notifications don't appear in taskbar -->
    <windowRule matchClass="Mako-Notifier">
      <skipTaskbar>yes</skipTaskbar>
      <skipWindowSwitcher>yes</skipWindowSwitcher>
    </windowRule>

    <!-- Dialogs are floating -->
    <windowRule matchRole="dialog">
      <floating>yes</floating>
    </windowRule>

    <!-- Specific programs floating -->
    <windowRule matchClass="Gnome-calculator">
      <floating>yes</floating>
    </windowRule>
  </windowRules>

</labwc_config>
EOF

echo "=== Labwc setup finished! ==="
echo "Please restart your session or computer to apply changes."