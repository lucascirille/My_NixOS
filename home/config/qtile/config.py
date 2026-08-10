import os
import libqtile.resources
from libqtile import bar, layout, qtile
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from qtile_extras import widget
from qtile_extras.widget.decorations import RectDecoration

mod = "mod4"
terminal = guess_terminal()

# -------------------------------------------------------------------------
# 1. Unified Theme Control
# -------------------------------------------------------------------------
colors = {
    "bg": "#1a1b26",
    "surface": "#24283b",
    "fg": "#a9b1d6",
    "accent": "#7aa2f7",
    "critical": "#f7768e",
    "ok": "#9ece6a",
}

widget_defaults = dict(
    font="JetBrains Mono",
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()

# -------------------------------------------------------------------------
# 2. Functional & Hardware Detection Helpers
# -------------------------------------------------------------------------
def has_battery():
    """Checks if a battery device exists in sysfs (Laptops)."""
    sys_power = "/sys/class/power_supply"
    if os.path.exists(sys_power):
        return any(dev.startswith("BAT") for dev in os.listdir(sys_power))
    return False

def get_backlight_name():
    """Detects available backlight device name (Intel, AMD, ACPI, etc.)."""
    sys_backlight = "/sys/class/backlight"
    if os.path.exists(sys_backlight):
        devices = os.listdir(sys_backlight)
        if devices:
            return devices[0]
    return None

def volume_osd(action):
    """Generates complex shell sequences safely for dunst volume bars."""
    if action == "up":
        cmd = "pamixer -i 5 && dunstify -a System -u low -h string:x-dunst-stack-tag:volume -h int:value:$(pamixer --get-volume) 'Volume'"
    elif action == "down":
        cmd = "pamixer -d 5 && dunstify -a System -u low -h string:x-dunst-stack-tag:volume -h int:value:$(pamixer --get-volume) 'Volume'"
    else:
        cmd = "pamixer -t && ([ $(pamixer --get-mute) = true ] && dunstify -a System -u low -h string:x-dunst-stack-tag:volume 'Muted 󰝟' || dunstify -a System -u low -h string:x-dunst-stack-tag:volume -h int:value:$(pamixer --get-volume) 'Unmuted 󰕾')"
    return f"sh -c \"{cmd}\""

def brightness_osd(action):
    """Generates complex shell sequences safely for dunst brightness bars."""
    if action == "up":
        cmd = "brightnessctl set +5% && dunstify -a System -u low -h string:x-dunst-stack-tag:brightness -h int:value:$(brightnessctl -m | cut -d, -f4 | tr -d '%') 'Brightness 󰃟'"
    elif action == "down":
        cmd = "brightnessctl set 5%- && dunstify -a System -u low -h string:x-dunst-stack-tag:brightness -h int:value:$(brightnessctl -m | cut -d, -f4 | tr -d '%') 'Brightness 󰃟'"
    return f"sh -c \"{cmd}\""

def get_decoration(color, is_group=True):
    """Optimized decoration builder to keep code DRY."""
    return {
        "decorations": [
            RectDecoration(colour=color, radius=8, filled=True, padding_y=4, group=is_group)
        ],
        "padding": 10,
    }

# -------------------------------------------------------------------------
# 3. Universal Bar Instance Generator
# -------------------------------------------------------------------------
def create_bar(primary=True):
    """Returns a fresh Bar instance customized for any hardware or display backend."""
    
    # Core widgets for all systems (Desktop, Laptop, VM)
    bar_widgets = [
        widget.GroupBox(
            highlight_method='line',
            highlight_color=[colors["bg"], colors["accent"]],
            active=colors["ok"],
            inactive=colors["fg"],
            **get_decoration(colors["bg"])
        ),
        widget.Spacer(length=8),
        widget.WindowName(
            foreground=colors["accent"],
            max_chars=40,
            **get_decoration(colors["bg"])
        ),
        widget.Spacer(),
        widget.CPU(
            format='  {load_percent}%',
            update_interval=5.0,
            mouse_callbacks={'Button1': lazy.spawn("ghostty -e btop")},
            **get_decoration(colors["surface"])
        ),
        widget.Memory(
            format='  {MemUsed: .0f}MB',
            update_interval=5.0,
            **get_decoration(colors["surface"])
        ),
    ]

    # Conditionally add Backlight widget (Laptops only)
    backlight_dev = get_backlight_name()
    if backlight_dev:
        bar_widgets.append(
            widget.Backlight(
                backlight_name=backlight_dev,
                format='󰃟  {percent:2.0%}',
                update_interval=2.0,
                **get_decoration(colors["surface"])
            )
        )

    # Conditionally add Battery widget (Laptops only)
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
                **get_decoration(colors["surface"])
            )
        )

    # Append volume and clock
    bar_widgets.extend([
        widget.PulseVolume(
            fmt='󰕾 {}',
            limit_max_volume=True,
            mouse_callbacks={'Button1': lazy.spawn("pavucontrol")}, 
            **get_decoration(colors["accent"]),
            foreground=colors["bg"]
        ),
        widget.Clock(
            format='󰃭 %d/%m %H:%M',
            **get_decoration(colors["ok"]),
            foreground=colors["bg"]
        ),
       # Universal Dual-Backend Power Menu
        widget.TextBox(
            text="󰐥",
            fontsize=14,
            mouse_callbacks={
                'Button1': lazy.spawn(
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
            },
            **get_decoration(colors["critical"]),
            foreground=colors["bg"],
        ), 
    ])


    # System tray handling (Only on primary monitor to avoid multi-monitor crashes)
    if primary:
        if getattr(qtile, "core", None) and qtile.core.name == "wayland":
            # StatusNotifier works natively on Wayland
            bar_widgets.append(widget.StatusNotifier(padding=5))
        else:
            # Systray for X11
            bar_widgets.append(widget.Systray(padding=5))

    return bar.Bar(
        bar_widgets,
        34,
        margin=[6, 10, 6, 10],
        background="#00000000",
    )

# -------------------------------------------------------------------------
# 4. Keyboard Shortcuts & Input Mapping
# -------------------------------------------------------------------------
keys = [
    # Navigation & Management Defaults
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
    
    # App Launchers
    Key([mod], "b", lazy.spawn("brave")),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Launch application launcher"),
    Key([mod], "r", lazy.spawn("rofi -show run"), desc="Run terminal command"),

    # Dunst Control
    Key(["control"], "space", lazy.spawn("dunstctl close"), desc="Close latest notification"),
    Key(["control", "shift"], "space", lazy.spawn("dunstctl close-all"), desc="Close all notifications"),
    Key(["control"], "grave", lazy.spawn("dunstctl history-pop"), desc="Show notification history"),

    # Hardware Multimedia Keys
    Key([], "XF86AudioRaiseVolume", lazy.spawn(volume_osd("up"))),
    Key([], "XF86AudioLowerVolume", lazy.spawn(volume_osd("down"))),
    Key([], "XF86AudioMute", lazy.spawn(volume_osd("mute"))),

    # Hardware Brightness Keys
    Key([], "XF86MonBrightnessUp", lazy.spawn(brightness_osd("up")), desc="Increase brightness with OSD"),
    Key([], "XF86MonBrightnessDown", lazy.spawn(brightness_osd("down")), desc="Decrease brightness with OSD"),

    # Manage Power ON/OF
    Key([mod, "shift"], "e", lazy.spawn(
            "sh -c 'choice=$(printf \"󰐥 Power Off\\n󰜉 Reboot\\n󰤄 Suspend\\n󰌾 Lock\\n󰍃 Logout\" | "
                    "rofi -dmenu -i -p \"Power\") && "
                    "case \"$choice\" in "
                    "\"󰐥 Power Off\") systemctl poweroff ;; "
                    "\"󰜉 Reboot\") systemctl reboot ;; "
                    "\"󰤄 Suspend\") systemctl suspend ;; "
                    "\"󰌾 Lock\") if [ -n \"$WAYLAND_DISPLAY\" ]; then swaylock -f -c 000000; else i3lock-color --blur=5; fi ;; "
                    "\"󰍃 Logout\") loginctl terminate-session self ;; "
                    "esac'"
    ), desc="Open Power Menu"),

]



# Virtual Console Mappings (Wayland safe)
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: getattr(qtile, "core", None) and qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )

# -------------------------------------------------------------------------
# 5. Groups, Layouts & Screen Setup
# -------------------------------------------------------------------------
groups = [Group(i) for i in "123456789"]
for i in groups:
    keys.extend([
        Key([mod], i.name, lazy.group[i.name].toscreen(), desc=f"Switch to group {i.name}"),
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=True)),
    ])

layouts = [
    layout.Columns(border_focus_stack=["#d75f5f", "#8f3d3d"], border_width=4),
    layout.Max(),
]

logo = os.path.join(os.path.dirname(libqtile.resources.__file__), "logo.png")
screens = [
    Screen(
        top=create_bar(primary=True),
        background="#000000",
        wallpaper=logo,
        wallpaper_mode="center",
    ),
]

# Mouse Bindings & Compositor Settings
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
    ]
)

auto_fullscreen = True
focus_on_window_activation = "smart"
focus_previous_on_window_remove = False
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None
wl_xcursor_theme = None
wl_xcursor_size = 24
wmname = "LG3D"
