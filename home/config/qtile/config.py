# =========================================================================
# 0. IMPORTS (Grouped and ordered by PEP 8 standard)
# =========================================================================
# Standard Python libraries
import os
import json
import shutil
import subprocess

# Qtile Core
import libqtile.resources
from libqtile import bar, hook, layout, qtile
from libqtile.config import Click, Drag, DropDown, Group, Key, Match, ScratchPad, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

# Qtile Extras (qtile_extras)
from qtile_extras import widget
from qtile_extras.widget.decorations import RectDecoration

# =========================================================================
# 1. GLOBAL VARIABLES & THEME (Full Wallpaper-Derived Stylix Integration)
# =========================================================================
mod = "mod4"
terminal = guess_terminal()
stylix_colors_path = os.path.expanduser("~/.config/stylix/colors.json")

# Base dictionary (Fallback palette if JSON is missing)
stylix = {
    "base00": "#1a1b26", "base01": "#24283b", "base02": "#414868", 
    "base03": "#565f89", "base04": "#c0caf5", "base05": "#a9b1d6", 
    "base06": "#cfc9c2", "base07": "#3d59a1", "base08": "#f7768e", 
    "base09": "#ff9e64", "base0A": "#e0af68", "base0B": "#9ece6a", 
    "base0C": "#7dcfff", "base0D": "#7aa2f7", "base0E": "#bb9af7", 
    "base0F": "#b4f9f8"
}

# Overwrite fully with the wallpaper-derived palette from Nix
try:
    with open(stylix_colors_path, "r") as f:
        data = json.load(f)
        if isinstance(data, dict):
            stylix.update(data)
except (FileNotFoundError, json.JSONDecodeError):
    pass

wallpaper_path = stylix.get("image", os.path.expanduser("~/.dotfiles/home/assets/Wallpapers/current.jpg"))

# Fully mapped to wallpaper-extracted Base16 colors
colors = {
    "bg": stylix["base00"],         # Wallpaper background tone
    "surface": stylix["base01"],    # Wallpaper surface tone
    "fg": stylix["base05"],         # Wallpaper foreground/text tone
    
    # Fully dynamic accents derived from your current wallpaper
    "accent": stylix["base0D"],     # Primary wallpaper accent (Blue-ish)
    "critical": stylix["base08"],   # Wallpaper error/red tone
    "ok": stylix["base0B"],         # Wallpaper success/green tone
    "warning": stylix["base0A"],    # Wallpaper warning/yellow tone
    "orange": stylix["base09"],     # Wallpaper orange tone
    "cyan": stylix["base0C"],       # Wallpaper cyan tone
    "magenta": stylix["base0E"],    # Wallpaper magenta tone
}

widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=14,
    padding=3,
)
extension_defaults = widget_defaults.copy()

# =========================================================================
# 2. HARDWARE & UTILITY FUNCTIONS
# =========================================================================
def get_wlan_interface():
    sys_net = "/sys/class/net"
    if os.path.exists(sys_net):
        for dev in os.listdir(sys_net):
            if dev.startswith("w") and dev != "wg0":
                return dev
    return None

def has_battery():
    sys_power = "/sys/class/power_supply"
    if os.path.exists(sys_power):
        return any(dev.startswith("BAT") for dev in os.listdir(sys_power))
    return False

def get_backlight_name():
    sys_backlight = "/sys/class/backlight"
    if os.path.exists(sys_backlight):
        devices = os.listdir(sys_backlight)
        if devices:
            return devices[0]
    return None

def volume_osd(action):
    if action == "up":
        cmd = "pamixer -i 5 && dunstify -a System -u low -h string:x-dunst-stack-tag:volume -h int:value:$(pamixer --get-volume) 'Volume'"
    elif action == "down":
        cmd = "pamixer -d 5 && dunstify -a System -u low -h string:x-dunst-stack-tag:volume -h int:value:$(pamixer --get-volume) 'Volume'"
    else:
        cmd = "pamixer -t && ([ $(pamixer --get-mute) = true ] && dunstify -a System -u low -h string:x-dunst-stack-tag:volume 'Muted 󰝟' || dunstify -a System -u low -h string:x-dunst-stack-tag:volume -h int:value:$(pamixer --get-volume) 'Unmuted 󰕾')"
    return f"sh -c \"{cmd}\""

def brightness_osd(action):
    if action == "up":
        cmd = "brightnessctl set +5% && dunstify -a System -u low -h string:x-dunst-stack-tag:brightness -h int:value:$(brightnessctl -m | cut -d, -f4 | tr -d '%') 'Brightness 󰃟'"
    elif action == "down":
        cmd = "brightnessctl set 5%- && dunstify -a System -u low -h string:x-dunst-stack-tag:brightness -h int:value:$(brightnessctl -m | cut -d, -f4 | tr -d '%') 'Brightness 󰃟'"
    return f"sh -c \"{cmd}\""

def power_menu_cmd():
    return (
        "sh -c 'choice=$(printf \"󰐥 Power Off\\n󰜉 Reboot\\n󰤄 Suspend\\n󰌾 Lock\\n󰍃 Logout\" | "
        "rofi -dmenu -i -p \"Power\") && "
        "case \"$choice\" in "
        "\"󰐥 Power Off\") systemctl poweroff ;; "
        "\"󰜉 Reboot\") systemctl reboot ;; "
        "\"󰤄 Suspend\") systemctl suspend ;; "
        "\"󰌾 Lock\") if [ -n \"$WAYLAND_DISPLAY\" ]; then swaylock -f -c 000000; else i3lock-color --blur=5; fi ;; "
        "\"󰍃 Logout\") loginctl terminate-session self ;; "
        "esac'"
    )

def get_decoration(color, is_group=True):
    return {
        "decorations": [
            RectDecoration(colour=color, radius=8, filled=True, padding_y=4, group=is_group)
        ],
        "padding": 10,
    }

# =========================================================================
# 3. BAR AND WIDGETS
# =========================================================================
def create_bar(primary=True):
    bar_widgets = [
        widget.GroupBox(
            highlight_method='line',
            highlight_color=[colors["bg"], colors["accent"]],
            active=colors["ok"],
            inactive=colors["fg"],
            **get_decoration(colors["bg"])
        ),
        widget.Spacer(length=8),
        
        widget.CurrentLayout(
            fmt='󰕰 {}',
            foreground=colors["bg"],
            **get_decoration(colors["magenta"])
        ),
        widget.Spacer(length=8),

        widget.WindowName(
            foreground=colors["accent"],
            max_chars=40,
            **get_decoration(colors["bg"])
        ),
        widget.Spacer(),
    ]

    if primary:
        if getattr(qtile, "core", None) and qtile.core.name == "wayland":
            bar_widgets.append(widget.StatusNotifier(padding=5))
        else:
            bar_widgets.append(widget.Systray(padding=5))
        bar_widgets.append(widget.Spacer(length=8))

    bar_widgets.extend([
        widget.CPU(
            format='  {load_percent}%',
            update_interval=5.0,
            mouse_callbacks={'Button1': lazy.group["scratchpad"].dropdown_toggle("btop")},
            foreground=colors["bg"],
            **get_decoration(colors["cyan"])
        ),
        widget.Memory(
            format='  {MemUsed: .0f}MB',
            update_interval=5.0,
            foreground=colors["bg"],
            **get_decoration(colors["warning"])
        ),
    ])

    backlight_dev = get_backlight_name()
    if backlight_dev:
        bar_widgets.append(
            widget.Backlight(
                backlight_name=backlight_dev,
                format='󰃟  {percent:2.0%}',
                step=5, 
                change_command='brightnessctl set {0}%',
                update_interval=2.0, 
                foreground=colors["bg"],
                **get_decoration(colors["warning"])
            )
        )

    wlan_dev = get_wlan_interface()
    if wlan_dev:
        bar_widgets.append(
            widget.Wlan(
                interface=wlan_dev,
                format='󰤨  {essid} {percent:2.0%}',
                disconnected_message='󰤭  Offline',
                update_interval=5.0,
                mouse_callbacks={'Button1': lazy.group["scratchpad"].dropdown_toggle("nmtui")},
                foreground=colors["bg"],
                **get_decoration(colors["accent"])
            )
        )

    if has_battery():
        bar_widgets.append(
            widget.Battery(
                format='{char} {percent:2.0%}',
                show_short_text=False,
                charge_char='󱐋 󰁹',
                discharge_char='󰁹',
                full_char='󰁹 Full',
                low_percentage=0.2,
                low_foreground=colors["critical"],
                update_interval=15,
                foreground=colors["fg"],
                **get_decoration(colors["surface"])
            )
        )

    bar_widgets.extend([
        widget.PulseVolume(
            fmt='󰕾 {}',
            limit_max_volume=True,
            mouse_callbacks={'Button1': lazy.spawn("pavucontrol")}, 
            foreground=colors["bg"],
            **get_decoration(colors["ok"])
        ),
        widget.Clock(
            format='󰃭 %d/%m %H:%M',
            foreground=colors["accent"],
            **get_decoration(colors["surface"])
        ),
        widget.TextBox(
            text="󰐥",
            fontsize=14,
            mouse_callbacks={'Button1': lazy.spawn(power_menu_cmd())},
            foreground=colors["bg"],
            **get_decoration(colors["critical"]),
        ), 
    ])

    return bar.Bar(
        bar_widgets,
        34,
        margin=[6, 10, 6, 10],
        background="#00000000",
    )

# =========================================================================
# 4. KEYBINDINGS
# =========================================================================
keys = [
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), desc="Toggle split"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    
    Key([mod], "b", lazy.spawn("brave")),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Launch application launcher"),
    Key([mod], "r", lazy.spawn("rofi -show run"), desc="Run terminal command"),

    Key(["control"], "space", lazy.spawn("dunstctl close"), desc="Close latest notification"),
    Key(["control", "shift"], "space", lazy.spawn("dunstctl close-all"), desc="Close all notifications"),
    Key(["control"], "grave", lazy.spawn("dunstctl history-pop"), desc="Show notification history"),

    Key([], "XF86AudioRaiseVolume", lazy.spawn(volume_osd("up"))),
    Key([], "XF86AudioLowerVolume", lazy.spawn(volume_osd("down"))),
    Key([], "XF86AudioMute", lazy.spawn(volume_osd("mute"))),
    Key([], "XF86MonBrightnessUp", lazy.spawn(brightness_osd("up")), desc="Increase brightness"),
    Key([], "XF86MonBrightnessDown", lazy.spawn(brightness_osd("down")), desc="Decrease brightness"),

    Key([mod, "shift"], "e", lazy.spawn(power_menu_cmd()), desc="Open Power Menu"),

    Key([mod, "shift"], "s", lazy.spawn("flameshot gui")),
    Key([], "Print", lazy.spawn(
        "bash -c 'mkdir -p ~/Pictures/Screenshots && "
        "if [ -n \"$WAYLAND_DISPLAY\" ]; then "
        "grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && wl-copy < ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png; "
        "else maim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png | xclip -selection clipboard -t image/png; fi'"
    )),
    Key(["shift"], "Print", lazy.spawn(
        "bash -c 'if [ -n \"$WAYLAND_DISPLAY\" ]; then grim -g \"$(slurp)\" - | wl-copy; else maim -s | xclip -selection clipboard -t image/png; fi'"
    )),
]

for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"], f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: getattr(qtile, "core", None) and qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )

# =========================================================================
# 5. GROUPS & SCRATCHPAD
# =========================================================================
group_labels = [
    ("1", " "), ("2", "󰈹 "), ("3", "󰨞 "), 
    ("4", " "), ("5", "󰙯 "), ("6", "󰓇 "), 
    ("7", "󰎆 "), ("8", "󰙴 "), ("9", "󰕧 "),
]

groups = [Group(name, label=label) for name, label in group_labels]

for i in groups:
    keys.extend([
        Key([mod], i.name, lazy.group[i.name].toscreen(), desc=f"Switch to group {i.name}"),
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=True)),
    ])

groups.append(
    ScratchPad("scratchpad", [
        # 1. Main Terminal (Mod + F12)
        DropDown(
            "term",
            "ghostty --title=scratchterm --gtk-single-instance=false",
            match=Match(title="scratchterm"),
            width=0.6, height=0.6, x=0.2, y=0.2, opacity=0.95,
            on_focus_lost_hide=False
        ),
        # 2. System Monitor (For CPU Widget)
        DropDown(
            "btop",
            "ghostty --title=scratchbtop --gtk-single-instance=false -e btop",
            match=Match(title="scratchbtop"),
            width=0.7, height=0.7, x=0.15, y=0.15, opacity=0.95,
            on_focus_lost_hide=False
        ),
        # 3. Network Manager (For Wlan Widget)
        DropDown(
            "nmtui",
            "ghostty --title=scratchnmtui --gtk-single-instance=false -e nmtui",
            match=Match(title="scratchnmtui"),
            width=0.4, height=0.5, x=0.3, y=0.25, opacity=0.95,
            on_focus_lost_hide=False
        ),
    ])
)

keys.append(Key([mod], "F12", lazy.group["scratchpad"].dropdown_toggle("term")))

# =========================================================================
# 6. LAYOUTS AND SCREENS
# =========================================================================
layouts = [
    layout.Columns(
        border_focus=colors["accent"],
        border_normal=colors["surface"],
        border_focus_stack=[colors["orange"], colors["magenta"]],
        border_normal_stack=[colors["surface"], colors["surface"]],
        border_width=4
    ),
    layout.Max(),
]

logo = os.path.join(os.path.dirname(libqtile.resources.__file__), "logo.png")
screens = [
    Screen(
        wallpaper=wallpaper_path,
        wallpaper_mode="fill",
        top=create_bar(primary=True),
        background="#000000",
    ),
]

# =========================================================================
# 7. MOUSE AND FLOATING RULES
# =========================================================================
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False

floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
    ],
    border_focus=colors["accent"],
    border_normal=colors["surface"],
    border_width=4
)

auto_fullscreen = True
focus_on_window_activation = "smart"
focus_previous_on_window_remove = False
reconfigure_screens = True
auto_minimize = False
wl_input_rules = None
wl_xcursor_theme = None
wl_xcursor_size = 24
wmname = "qtile"
