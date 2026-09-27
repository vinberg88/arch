#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"
TARGET="/usr/local/bin/kde6-x410"
STATE_DIR="$HOME/.local/state/kde6-x410"

ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; }

if [[ $EUID -eq 0 ]]; then
    err "Do not run this installer as root or with sudo."
    echo "Run it as your normal Arch WSL user. The installer uses sudo when required."
    exit 1
fi

echo
echo "=================================================="
echo "      Arch Linux KDE Plasma 6 / X410 Installer"
echo "                     $VERSION"
echo "=================================================="
echo

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    info "Distribution: ${PRETTY_NAME:-unknown}"
    [[ "${ID:-}" == "arch" ]] || warn "This installer is intended for Arch Linux."
fi

grep -qi microsoft /proc/version 2>/dev/null     && ok "WSL detected."     || warn "WSL was not detected."

command -v sudo >/dev/null 2>&1 || {
    err "sudo is required."
    exit 1
}

command -v pacman >/dev/null 2>&1 || {
    err "pacman was not found."
    exit 1
}

echo
echo "[1/4] Checking KDE Plasma 6 X11 packages..."

missing_kde=()
for pkg in plasma-x11-session kwin-x11; do
    pacman -Q "$pkg" >/dev/null 2>&1 || missing_kde+=("$pkg")
done

if (("${#missing_kde[@]}" > 0)); then
    warn "Missing required X11 package(s): ${missing_kde[*]}"
    echo
    echo "Install them with:"
    echo "  sudo pacman -Syu --needed plasma-x11-session kwin-x11"
    echo
    echo "or:"
    echo "  paru -S plasma-x11-session kwin-x11"
    echo
    exit 1
fi

ok "plasma-x11-session and kwin-x11 are installed."

echo
echo "[2/4] Installing small X410/diagnostic dependencies..."
sudo pacman -S --needed --noconfirm     xorg-xdpyinfo     xorg-xset     xorg-xrandr     dbus     iproute2     procps-ng     coreutils

echo
echo "[3/4] Installing kde6-x410 launcher..."

mkdir -p "$STATE_DIR"
if [[ ! -w "$STATE_DIR" ]]; then
    warn "$STATE_DIR is not writable. Repairing ownership..."
    sudo chown -R "$(id -u):$(id -g)" "$STATE_DIR"
fi

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

cat > "$tmpfile" <<'LAUNCHER'
#!/usr/bin/env bash
set -u

VERSION="0.1.0"
STATE_DIR="$HOME/.local/state/kde6-x410"
LOG_FILE="$STATE_DIR/session.log"
PID_FILE="$STATE_DIR/session.pid"

mkdir -p "$STATE_DIR"

ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; }

candidate_hosts() {
    [[ -n "${X410_HOST:-}" ]] && printf '%s\n' "$X410_HOST"

    ip route show default 2>/dev/null |
        awk '/default/ {print $3; exit}'

    awk '/^nameserver[[:space:]]+/ {print $2; exit}' /etc/resolv.conf 2>/dev/null || true

    printf '%s\n' "127.0.0.1"
}

detect_display() {
    local host display seen=""

    while IFS= read -r host; do
        [[ -z "$host" ]] && continue
        case " $seen " in
            *" $host "*) continue ;;
        esac
        seen+=" $host"

        display="${host}:0.0"

        if command -v timeout >/dev/null 2>&1; then
            if timeout 3 env DISPLAY="$display" xdpyinfo >/dev/null 2>&1; then
                printf '%s\n' "$display"
                return 0
            fi
        elif env DISPLAY="$display" xdpyinfo >/dev/null 2>&1; then
            printf '%s\n' "$display"
            return 0
        fi
    done < <(candidate_hosts)

    host="$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')"
    [[ -z "$host" ]] && host="$(awk '/^nameserver[[:space:]]+/ {print $2; exit}' /etc/resolv.conf 2>/dev/null)"
    [[ -z "$host" ]] && host="127.0.0.1"

    printf '%s\n' "${host}:0.0"
    return 1
}

setup_environment() {
    local detected
    detected="$(detect_display 2>/dev/null || true)"
    [[ -z "$detected" ]] && detected="127.0.0.1:0.0"

    export DISPLAY="$detected"

    # Keep the entire Plasma session on X410/X11 instead of WSLg/Wayland.
    unset WAYLAND_DISPLAY
    unset WAYLAND_SOCKET

    export XDG_SESSION_TYPE=x11
    export XDG_CURRENT_DESKTOP=KDE
    export XDG_SESSION_DESKTOP=KDE
    export DESKTOP_SESSION=plasma
    export KDE_FULL_SESSION=true
    export KDE_SESSION_VERSION=6

    export QT_QPA_PLATFORM=xcb
    export GDK_BACKEND=x11
    export SDL_VIDEODRIVER=x11

    export XDG_RUNTIME_DIR="/run/user/$(id -u)"

    if [[ -S "$XDG_RUNTIME_DIR/bus" ]]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    fi

    # X410 handles graphics, WSLg keeps PulseAudio available.
    if [[ -S /mnt/wslg/PulseServer ]]; then
        export PULSE_SERVER="unix:/mnt/wslg/PulseServer"
    fi
}

check_x410() {
    setup_environment
    timeout 4 env DISPLAY="$DISPLAY" xdpyinfo >/dev/null 2>&1
}

import_environment() {
    systemctl --user unset-environment         WAYLAND_DISPLAY WAYLAND_SOCKET         >/dev/null 2>&1 || true

    systemctl --user import-environment         DISPLAY         XDG_RUNTIME_DIR         XDG_SESSION_TYPE         XDG_CURRENT_DESKTOP         XDG_SESSION_DESKTOP         DESKTOP_SESSION         KDE_FULL_SESSION         KDE_SESSION_VERSION         QT_QPA_PLATFORM         GDK_BACKEND         SDL_VIDEODRIVER         PULSE_SERVER         DBUS_SESSION_BUS_ADDRESS         >/dev/null 2>&1 || true

    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
        dbus-update-activation-environment --systemd             DISPLAY             XDG_RUNTIME_DIR             XDG_SESSION_TYPE             XDG_CURRENT_DESKTOP             XDG_SESSION_DESKTOP             DESKTOP_SESSION             KDE_FULL_SESSION             KDE_SESSION_VERSION             QT_QPA_PLATFORM             GDK_BACKEND             SDL_VIDEODRIVER             PULSE_SERVER             >/dev/null 2>&1 || true
    fi
}

running() {
    pgrep -u "$(id -u)" -x plasmashell >/dev/null 2>&1 ||
    pgrep -u "$(id -u)" -x kwin_x11 >/dev/null 2>&1
}

pkg_version() {
    pacman -Q "$1" 2>/dev/null | awk '{print $2}' || echo "missing"
}

doctor() {
    setup_environment

    local x410="NOT reachable"
    local user_systemd
    local status="CHECK REQUIRED"

    check_x410 >/dev/null 2>&1 && x410="reachable"
    user_systemd="$(systemctl --user is-system-running 2>/dev/null || true)"

    echo
    echo "   Arch Linux KDE6 X410 $VERSION"
    echo "=================================================="

    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        printf "%-26s %s\n" "Distribution:" "${PRETTY_NAME:-Arch Linux}"
    fi

    printf "%-26s %s\n" "Kernel:" "$(uname -r)"
    printf "%-26s %s\n" "WSL:" "$(grep -qi microsoft /proc/version 2>/dev/null && echo yes || echo no)"
    printf "%-26s %s\n" "User:" "$(whoami)"
    printf "%-26s %s\n" "UID:" "$(id -u)"
    printf "%-26s %s\n" "PID 1:" "$(ps -p 1 -o comm= 2>/dev/null || echo unknown)"
    printf "%-26s %s\n" "User systemd:" "${user_systemd:-unavailable}"
    printf "%-26s %s\n" "X410 DISPLAY:" "$DISPLAY"
    printf "%-26s %s\n" "X410:" "$x410"
    printf "%-26s %s\n" "plasma-x11-session:" "$(pkg_version plasma-x11-session)"
    printf "%-26s %s\n" "kwin-x11:" "$(pkg_version kwin-x11)"

    for cmd in startplasma-x11 kwin_x11 plasmashell; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf "%-26s %s\n" "$cmd:" "$(command -v "$cmd")"
        else
            printf "%-26s %s\n" "$cmd:" "MISSING"
        fi
    done

    if [[ -S /mnt/wslg/PulseServer ]]; then
        printf "%-26s %s\n" "WSLg audio socket:" "yes"
    else
        printf "%-26s %s\n" "WSLg audio socket:" "no"
    fi

    if running; then
        printf "%-26s %s\n" "Plasma session:" "RUNNING"
    else
        printf "%-26s %s\n" "Plasma session:" "stopped"
    fi

    if [[ "$x410" == "reachable" ]]         && command -v startplasma-x11 >/dev/null 2>&1         && command -v kwin_x11 >/dev/null 2>&1         && command -v plasmashell >/dev/null 2>&1; then
        status="READY"
    fi

    printf "%-26s %s\n" "Status:" "$status"
    echo
}

start_session() {
    setup_environment

    if ! check_x410; then
        err "X410 does not respond on DISPLAY=$DISPLAY"
        echo
        echo "Start X410 in Windows 11 first."
        echo "Then run:"
        echo "  kde6-x410 doctor"
        exit 1
    fi

    ok "X410 responds on DISPLAY=$DISPLAY"

    if [[ -S /mnt/wslg/PulseServer ]]; then
        ok "WSLg audio available via /mnt/wslg/PulseServer"
    else
        warn "WSLg PulseAudio socket was not found."
    fi

    for cmd in startplasma-x11 kwin_x11 plasmashell; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            err "Missing command: $cmd"
            exit 1
        fi
    done

    if running; then
        warn "A Plasma session already appears to be running."
        echo "Run: kde6-x410 restart"
        exit 1
    fi

    import_environment

    rm -f "$PID_FILE"
    : > "$LOG_FILE"

    echo
    echo "[Arch KDE6 X410] Starting KDE Plasma 6 X11..."
    echo "[Arch KDE6 X410] DISPLAY=$DISPLAY"
    echo "[Arch KDE6 X410] Log: $LOG_FILE"
    echo

    nohup setsid /usr/bin/startplasma-x11 >>"$LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"

    sleep 6

    if running; then
        ok "KDE Plasma 6 is running on X410."
        echo
        echo "DISPLAY: $DISPLAY"
        echo "Session: X11"
        echo
    else
        err "Plasma did not appear to start correctly."
        echo
        echo "Last log lines:"
        echo "--------------------------------------------------"
        tail -n 60 "$LOG_FILE" 2>/dev/null || true
        echo "--------------------------------------------------"
        exit 1
    fi
}

stop_session() {
    echo "[Arch KDE6 X410] Stopping Plasma..."

    if command -v kquitapp6 >/dev/null 2>&1; then
        kquitapp6 plasmashell >/dev/null 2>&1 || true
    fi

    sleep 1

    pkill -u "$(id -u)" -x plasmashell 2>/dev/null || true
    pkill -u "$(id -u)" -x kwin_x11 2>/dev/null || true
    pkill -u "$(id -u)" -f '/usr/bin/startplasma-x11' 2>/dev/null || true

    if [[ -f "$PID_FILE" ]]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
    fi

    rm -f "$PID_FILE"
    sleep 2

    running         && warn "Some Plasma processes are still running."         || ok "KDE Plasma 6 stopped."
}

repair_session() {
    info "Stopping the current/partial Plasma session..."
    stop_session || true

    info "Clearing Plasma runtime caches. KDE settings are preserved."
    rm -rf "$HOME/.cache/plasmashell"* 2>/dev/null || true
    rm -f "$HOME/.cache/ksycoca6_"* 2>/dev/null || true

    if command -v kbuildsycoca6 >/dev/null 2>&1; then
        kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
    fi

    ok "Repair completed."
    echo "Start X410 in Windows 11 and run:"
    echo "  kde6-x410 start"
}

show_log() {
    if [[ -f "$LOG_FILE" ]]; then
        tail -n 120 "$LOG_FILE"
    else
        echo "No session log yet."
    fi
}

case "${1:-doctor}" in
    start)
        start_session
        ;;
    stop)
        stop_session
        ;;
    restart)
        stop_session
        sleep 2
        start_session
        ;;
    repair)
        repair_session
        ;;
    doctor|status)
        doctor
        ;;
    log)
        show_log
        ;;
    version|--version|-v)
        echo "Arch Linux KDE6 X410 $VERSION"
        ;;
    *)
        echo "Usage:"
        echo "  kde6-x410 doctor"
        echo "  kde6-x410 start"
        echo "  kde6-x410 stop"
        echo "  kde6-x410 restart"
        echo "  kde6-x410 repair"
        echo "  kde6-x410 log"
        exit 1
        ;;
esac
LAUNCHER

chmod 755 "$tmpfile"
sudo install -m 0755 "$tmpfile" "$TARGET"

echo
echo "[4/4] Installation complete."
echo
ok "Installed: $TARGET"
echo
echo "IMPORTANT - X410 must be running in Windows 11."
echo
echo "Run:"
echo "  kde6-x410 doctor"
echo
echo "If Plasma is currently half-started/broken:"
echo "  kde6-x410 repair"
echo
echo "Then:"
echo "  kde6-x410 start"
echo
echo "Other commands:"
echo "  kde6-x410 stop"
echo "  kde6-x410 restart"
echo "  kde6-x410 log"
echo
