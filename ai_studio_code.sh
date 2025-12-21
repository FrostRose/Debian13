#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Mirror Configuration ---

# Backup original sources
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

# Warning: This overwrites /etc/apt/sources.list with Debian Trixie (Testing) mirrors.
# Ensure you intend to switch to the Testing branch.
sudo tee /etc/apt/sources.list << 'EOF'
deb https://mirrors.ustc.edu.cn/debian/ trixie main
deb https://mirrors.ustc.edu.cn/debian/ trixie-updates main
deb https://mirrors.ustc.edu.cn/debian-security trixie-security main
EOF

sudo apt update

# --- Installation ---

sudo apt install -y labwc waybar foot fuzzel thunar swaybg polkit-1 lxpolkit mako brightnessctl pavucontrol qt6-wayland xdg-desktop-portal-wlr xwayland \
grim slurp wl-clipboard swaylock cliphist network-manager-gnome \
fonts-noto-cjk fonts-font-awesome fcitx5 fcitx5-chinese-addons fcitx5-configtool \
libnotify-bin curl wget git gammastep \
flatpak adb fastboot

# --- Configuration ---

# Ensure config directories exist
mkdir -p ~/.config/labwc
mkdir -p ~/.config/waybar

# 1. Autostart
# Warning: Ensure ~/Pictures/wallpaper.jpg exists, otherwise swaybg will fail.
cat > ~/.config/labwc/autostart <<'EOF'
#!/bin/sh

dbus-update-activation-environment --systemd --all

/usr/bin/lxpolkit &

swaybg -i ~/Pictures/wallpaper.jpg -m fill &

fcitx5 -d &

mako &

waybar &

wl-paste --watch cliphist store &

gammastep -O 4500 &

labwc-menu-generator > ~/.config/labwc/menu.xml
EOF

chmod +x ~/.config/labwc/autostart

# 2. Menu XML
cat > ~/.config/labwc/menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu>

  <menu id="root-menu" label="Labwc">
    <menu id="apps-menu" label="应用程序" execute="labwc-menu-generator" />
    <separator />
    <menu id="system" label="系统管理" />
  </menu>

  <menu id="system" label="系统管理">
    <item label="音量控制">
      <action name="Execute"><command>pavucontrol</command></action>
    </item>
    <item label="截图 (全屏)">
      <action name="Execute">
        <command>sh -c 'mkdir -p ~/Pictures &amp;&amp; grim ~/Pictures/screenshot-$(date +%s).png &amp;&amp; notify-send "全屏截图已保存"'</command>
      </action>
    </item>
    <item label="截图 (选区)">
      <action name="Execute">
        <command>sh -c 'mkdir -p ~/Pictures &amp;&amp; grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%s).png &amp;&amp; notify-send "选区截图已保存"'</command>
      </action>
    </item>
    <separator />
    <menu id="power" label="电源选项">
      <item label="锁定屏幕"><action name="Execute"><command>swaylock -c 000000</command></action></item>
      <item label="重新配置"><action name="Reconfigure"/></item>
      <item label="退出 Labwc"><action name="Exit"/></item>
      <item label="重启"><action name="Execute"><command>systemctl reboot</command></action></item>
      <item label="关机"><action name="Execute"><command>systemctl poweroff</command></action></item>
    </menu>
  </menu>

</openbox_menu>
EOF

# 3. Environment Variables
cat > ~/.config/labwc/environment << 'EOF'
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx

export XDG_CURRENT_DESKTOP=labwc
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=labwc

export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM=wayland;xcb

export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland

export CLUTTER_BACKEND=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
EOF

# 4. RC XML (Keybinds)
cat > ~/.config/labwc/rc.xml << 'EOF'
<?xml version="1.0"?>
<labwc_config>

  <desktops number="4"/>

  <theme>
    <cornerRadius>8</cornerRadius>
    <titlebar><layout>LIMC</layout><showTitle>yes</showTitle></titlebar>
  </theme>

  <placement>
    <policy>Cascade</policy>
    <cascadeOffset x="30" y="20"/>
  </placement>

  <keyboard>
    <default/>

    <keybind key="W-Return"><action name="Execute"><command>foot</command></action></keybind>
    <keybind key="W-d"><action name="Execute"><command>fuzzel</command></action></keybind>
    <keybind key="W-l"><action name="Execute"><command>swaylock -c 000000</command></action></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="W-a"><action name="ToggleMaximize"/></keybind>
    <keybind key="W-f"><action name="ToggleFullscreen"/></keybind>

    <keybind key="W-1"><action name="GoToDesktop"><to>1</to></action></keybind>
    <keybind key="W-2"><action name="GoToDesktop"><to>2</to></action></keybind>
    <keybind key="W-3"><action name="GoToDesktop"><to>3</to></action></keybind>
    <keybind key="W-4"><action name="GoToDesktop"><to>4</to></action></keybind>

    <keybind key="XF86AudioLowerVolume"><action name="Execute"><command>pactl set-sink-volume @DEFAULT_SINK@ -5%</command></action></keybind>
    <keybind key="XF86AudioRaiseVolume"><action name="Execute"><command>pactl set-sink-volume @DEFAULT_SINK@ +5%</command></action></keybind>
    <keybind key="XF86AudioMute"><action name="Execute"><command>pactl set-sink-mute @DEFAULT_SINK@ toggle</command></action></keybind>
    <keybind key="W-Down"><action name="Execute"><command>pactl set-sink-volume @DEFAULT_SINK@ -5%</command></action></keybind>
    <keybind key="W-Up"><action name="Execute"><command>pactl set-sink-volume @DEFAULT_SINK@ +5%</command></action></keybind>

    <keybind key="XF86MonBrightnessDown"><action name="Execute"><command>brightnessctl set 10%-</command></action></keybind>
    <keybind key="XF86MonBrightnessUp"><action name="Execute"><command>brightnessctl set +10%</command></action></keybind>

    <keybind key="Print"><action name="Execute"><command>sh -c 'mkdir -p ~/Pictures &amp;&amp; grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%s).png &amp;&amp; notify-send "选区截图已保存"'</command></action></keybind>
    <keybind key="W-Print"><action name="Execute"><command>sh -c 'mkdir -p ~/Pictures &amp;&amp; grim ~/Pictures/screenshot-$(date +%s).png &amp;&amp; notify-send "全屏截图已保存"'</command></action></keybind>
  </keyboard>

  <mouse>
  </mouse>

  <windowRules>
    <windowRule matchClass="Mako"><skipTaskbar>yes</skipTaskbar><skipWindowSwitcher>yes</skipWindowSwitcher></windowRule>
    <windowRule matchRole="dialog"><floating>yes</floating></windowRule>
    <windowRule matchClass="Gnome-calculator"><floating>yes</floating></windowRule>
    <windowRule matchClass="Pavucontrol"><floating>yes</floating></windowRule>
  </windowRules>

</labwc_config>
EOF

# 5. Waybar Config
cat > ~/.config/waybar/config.jsonc << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "margin-top": 5,
    "margin-left": 5,
    "margin-right": 5,

    "modules-left": ["wlr/workspaces", "cpu", "memory"],
    "modules-center": ["clock"],
    "modules-right": ["network", "battery", "tray"],

    "wlr/workspaces": {
        "format": "{name}",
        "on-click": "activate",
        "sort-by-name": true
    },

    "cpu": {
        "format": "{usage}% ",
        "tooltip": false
    },
    "memory": {
        "format": "{used:0.1f}G "
    },
    "clock": {
        "format": "{:%H:%M %Y-%m-%d}",
        "format-alt": "{:%A, %B %d, %Y}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "Connected ",
        "format-disconnected": "Disconnected ⚠",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}",
        "on-click": "nm-connection-editor"
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""],
        "states": { "warning": 30, "critical": 15 }
    },
    "tray": {
        "spacing": 10
    }
}
EOF