# =========================================================================
# 0. IMPORTS 
# =========================================================================
# Standard Python libraries
import os
import json
import shutil
import subprocess
from datetime import datetime

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
# 1. GLOBAL VARIABLES & THEME (Stylix Integration)
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
    "bg": stylix["base00"],         
    "surface": stylix["base01"],    
    "fg": stylix["base05"],         
    "accent": stylix["base0D"],     
    "critical": stylix["base08"],   
    "ok": stylix["base0B"],         
    "warning": stylix["base0A"],    
    "orange": stylix["base09"],     
    "cyan": stylix["base0C"],       
    "magenta": stylix["base0E"],    
}

widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=14,
    padding=3,
)
extension_defaults = widget_defaults.copy()

# =========================================================================
# 2. HOOKS & DYNAMIC WORKSPACES
# =========================================================================
# --- Wallpaper State Management ---
_wallpaper_paused = False

@hook.subscribe.startup_once
def autostart_wallpaper():
    """Restarts wallpaper engine on boot to grab a clean audio clock."""
    qtile.call_later(2.0, lambda: subprocess.Popen(["systemctl", "--user", "restart", "linux-wallpaperengine.service"]))

def update_wallpaper_state():
    """Pauses the animated wallpaper when windows or scratchpads are open to save resources."""
    global _wallpaper_paused
    active_windows = 0

    # 1. Check normal windows in the active group
    if qtile.current_group:
        for w in qtile.current_group.windows:
            if getattr(w, "minimized", False):
                continue
            
            # Safely grab window properties
            try:
                name = getattr(w, "name", "")
                wm_class = w.window.get_wm_class() if hasattr(w, "window") and w.window else []
                if not wm_class:
                    wm_class = []
                elif isinstance(wm_class, str): 
                    wm_class = [wm_class]
                
                # Skip the wallpaper engine itself
                if "linux-wallpaperengine" in name or any("linux-wallpaperengine" in c for c in wm_class):
                    continue
            except Exception:
                pass
            
            active_windows += 1

    # 2. Check explicitly for active Scratchpads (Dropdowns)
    scratchpads = qtile.groups_map.get("scratchpad")
    if scratchpads and hasattr(scratchpads, "dropdowns"):
        active_windows += sum(1 for dp in scratchpads.dropdowns.values() if getattr(dp, "visible", False))

    # 3. Apply state changes only if necessary
    should_pause = (active_windows > 0)
    
    if should_pause and not _wallpaper_paused:
        subprocess.Popen(["pkill", "-STOP", "-f", "linux-wallpaperengine"])
        _wallpaper_paused = True
    elif not should_pause and _wallpaper_paused:
        subprocess.Popen(["pkill", "-CONT", "-f", "linux-wallpaperengine"])
        _wallpaper_paused = False

# --- Dynamic Icon Mapping System ---
ICON_CATEGORIES = {
    "󰈹": ["firefox", "brave", "chrome", "browser"],
    "": ["ghostty", "alacritty", "kitty", "term", "wezterm"],
    "󰨞": ["code", "codium", "nvim", "idea", "ide"],
    "": ["thunar", "nautilus", "dolphin", "files"],
    "": ["discord", "vesktop", "slack", "teams"],
    "󰓇": ["spotify", "music", "ncmpcpp"],
    "󰓓": ["spotify"],
}
DEFAULT_ICON = ""
_app_cache: dict[str, str] = {}

def get_app_display(wm_class: str) -> str:
    """Matches a window class to a Nerd Font icon via keyword, or generates a text fallback."""
    if wm_class in _app_cache:
        return _app_cache[wm_class]

    clean_name = wm_class.lower()

    for icon, keywords in ICON_CATEGORIES.items():
        if any(keyword in clean_name for keyword in keywords):
            _app_cache[wm_class] = icon 
            return icon                  
    
    formatted_text = wm_class.split('.')[-1].capitalize()
    if not formatted_text:
        formatted_text = "Window"
        
    fallback_result = f"{DEFAULT_ICON} {formatted_text}"
    _app_cache[wm_class] = fallback_result
    return fallback_result

def update_labels():
    """Iterates through all groups and updates labels based on open windows."""
    for group in qtile.groups_map.values():
        if group.name == "scratchpad":
            continue

        if not group.windows:
            group.label = group.name
            continue
            
        display_items = []
        for w in group.windows:
            try:
                wm_class_list = w.window.get_wm_class()
                raw_class = wm_class_list[1] if wm_class_list and len(wm_class_list) > 1 else (wm_class_list[0] if wm_class_list else "")
            except Exception:
                raw_class = ""
            
            item = get_app_display(raw_class)
            if item not in display_items:
                display_items.append(item)
        
        group.label = f"{group.name} {' '.join(display_items)}"
            
    for screen in qtile.screens:
        if hasattr(screen, "top") and screen.top:
            screen.top.draw()
        if hasattr(screen, "bottom") and screen.bottom:
            screen.bottom.draw()

@hook.subscribe.client_new
@hook.subscribe.client_killed
@hook.subscribe.setgroup
@hook.subscribe.client_focus
@hook.subscribe.group_window_add       # Catches when F12 hides the terminal in the scratchpad group
def update_group_labels(*args, **kwargs):
    """Triggers wallpaper and label updates when window states change."""
    # We use a 0.1s delay so Qtile has time to actually update the 'visible' state of the scratchpads
    qtile.call_later(0.1, update_wallpaper_state) 
    qtile.call_later(0.1, update_labels)

# =========================================================================
# 3. HARDWARE & UTILITY FUNCTIONS
# =========================================================================
def get_next_event():
    my_calendars = {
        "lucas.cirille@gmail.com": " ",
        "Amo las flores": "󰴈",
        "Tu Amor": "󱝁",
    }

    try:
        now = datetime.now()
        valid_events = []

        for cal_name, tag in my_calendars.items():
            try:
                cmd = ["gcalcli", "--calendar", cal_name, "agenda", "--tsv"]
                output = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
            except subprocess.CalledProcessError:
                continue 
                
            lines = [line for line in output.splitlines() if line.strip()]

            for line in lines:
                parts = line.split('\t')
                if len(parts) < 2:
                    continue
                
                start_date = parts[0].strip()
                if start_date == "start_date" or "date" in start_date.lower():
                    continue
                
                start_time = parts[1].strip()
                end_date = parts[2].strip() if len(parts) > 2 else start_date
                end_time = parts[3].strip() if len(parts) > 3 else ""
                title = parts[4].strip() if len(parts) > 4 else "Event"
                
                start_dt = None
                end_dt = None
                
                if start_time:
                    try:
                        start_dt = datetime.strptime(f"{start_date} {start_time}", "%Y-%m-%d %H:%M")
                        if end_time:
                            end_dt = datetime.strptime(f"{end_date} {end_time}", "%Y-%m-%d %H:%M")
                    except ValueError:
                        pass
                else:
                    try:
                        start_dt = datetime.strptime(start_date, "%Y-%m-%d")
                        end_dt = datetime.strptime(f"{start_date} 23:59", "%Y-%m-%d %H:%M")
                    except ValueError:
                        pass
                
                if end_dt and end_dt < now:
                    continue
                elif not end_dt and start_dt and start_dt < now:
                    continue
                    
                valid_events.append({
                    "start_str": start_time if start_time else "All Day",
                    "end_str": end_time,
                    "title": f"{title} {tag}", 
                    "start_dt": start_dt,
                    "end_dt": end_dt
                })
                
        if not valid_events:
            return "Free schedule"

        valid_events.sort(key=lambda x: x["start_dt"] if x["start_dt"] else datetime.min)
        first_event = valid_events[0]
        display_items = []
        
        def format_event(ev):
            time_block = f"{ev['start_str']}-{ev['end_str']}" if ev['end_str'] else ev['start_str']
            return f"{time_block} {ev['title']}"
            
        display_items.append(format_event(first_event))
        
        if first_event["start_str"] == "All Day":
            current_max_end = first_event["start_dt"] 
        else:
            current_max_end = first_event["end_dt"]
        
        if current_max_end:
            for event in valid_events[1:]:
                if event["start_dt"] and event["start_dt"] < current_max_end:
                    display_items.append(format_event(event))
                    if event["end_dt"] and event["end_dt"] > current_max_end:
                        current_max_end = event["end_dt"]
                else:
                    break 
                    
        display_text = " / ".join(display_items)
        return display_text[:85] + "..." if len(display_text) > 85 else display_text

    except Exception as e:
        return f"Err: {str(e)[:15]}"

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
# 4. BAR AND WIDGETS
# =========================================================================
def create_bar(primary=True):
    bar_widgets = [
        widget.GroupBox(
            highlight_method='line',
            this_current_screen_border=colors["accent"], 
            borderwidth=4,                               
            highlight_color=[colors["bg"], colors["bg"]],
            urgent_alert_method='line',
            urgent_border=colors["critical"],
            urgent_text=colors["critical"],
            active=colors["ok"],
            inactive=colors["fg"],
            disable_drag=True,
            padding_x=10,
            margin_y=3,
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
            empty_group_string="Desktop",
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
                mouse_callbacks={
                    'Button1': lazy.group["scratchpad"].dropdown_toggle("nmtui"),
                    'Button3': lazy.spawn("nm-connection-editor"),
                },
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
        # Reverted back to perfectly valid GenPollText
        widget.GenPollText(
            update_interval=300, 
            func=get_next_event,
            fmt='󰃭  {}',
            foreground=colors["bg"],
            mouse_callbacks={
                'Button1': lazy.group["scratchpad"].dropdown_toggle("calendar"), 
                'Button2': lazy.spawn("brave https://calendar.google.com"),       
                'Button3': lazy.spawn("brave https://calendar.google.com"),       
            },
            **get_decoration(colors["orange"])
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
# 5. KEYBINDINGS
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

    Key([mod], "w", lazy.spawn("change-theme"), desc="Change animated wallpaper and Stylix theme"),
    Key([mod], "p", lazy.spawn("pkill -STOP -f linux-wallpaperengine"), desc="Freeze Wallpaper"),
    Key([mod, "shift"], "p", lazy.spawn("pkill -CONT -f linux-wallpaperengine"), desc="Resume Wallpaper"),
    
    Key([mod], "b", lazy.spawn("brave")),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Launch application launcher"),
    Key([mod], "r", lazy.spawn("rofi -show run"), desc="Run terminal command"),

    Key([mod], "period", lazy.spawn("rofimoji --action type --files emojis nerd_font"), desc="Launch emoji picker"),

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
        "grim ~/Pictures/Screenshots/$(date +\%Y-\%m-\%d_\%H-\%M-\%S).png && wl-copy < ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png; "
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
# 6. GROUPS & SCRATCHPAD
# =========================================================================
groups = [Group(str(i)) for i in range(1, 10)]

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
        # 3. Google Calendar (Clicking the bar widget)
        DropDown(
            "calendar",
            "ghostty --title=scratchcal --gtk-single-instance=false -e bash -c 'gcalcli calw; exec bash'",
            match=Match(title="scratchcal"),
            width=0.6, height=0.6, x=0.2, y=0.2, opacity=0.95,
            on_focus_lost_hide=False
        ),
        # 4. Network Manager TUI (Clicking the bar widget)
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
# 7. LAYOUTS AND SCREENS
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
# 8. MOUSE AND FLOATING RULES
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
        Match(wm_class="linux-wallpaperengine"),
        Match(title="linux-wallpaperengine"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
        Match(wm_class="nm-connection-editor")
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
