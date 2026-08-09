#!/usr/bin/env bash
# ScreenShare Scripts — Linux SS Checker
# by Schwarzahn
# Covers Mint/Nobara/Ubuntu-style checks: /tmp, processes, history, trash, USB, hosts, packages, recent exts

set -u
ESC=$'\033'
BRAND="Schwarzahn"
TOOL="ScreenShare Scripts / Linux"

c_hot="${ESC}[38;2;255;35;35m"
c_bld="${ESC}[38;2;200;10;10m"
c_sh="${ESC}[38;2;60;0;0m"
c_dim="${ESC}[38;2;90;90;90m"
c_soft="${ESC}[38;2;180;180;180m"
c_ok="${ESC}[38;2;80;220;120m"
c_warn="${ESC}[38;2;230;180;40m"
c_rst="${ESC}[0m"
c_bold="${ESC}[1m"

hits=0
warns=0

section() {
  echo ""
  echo -e "${c_dim}┌─${c_hot}▓${c_rst} ${c_soft}$1${c_rst} ${c_dim}$(printf '─%.0s' {1..40})${c_rst}"
}

ok()   { echo -e "  ${c_ok}[+]${c_rst} $*"; }
warn() { echo -e "  ${c_warn}[!]${c_rst} $*"; warns=$((warns+1)); }
bad()  { echo -e "  ${c_hot}[x]${c_rst} $*"; hits=$((hits+1)); }
info() { echo -e "  ${c_dim}[*]${c_rst} $*"; }

banner() {
  echo ""
  echo -e "${c_sh}  ███████╗ ██████╗██╗  ██╗██╗    ██╗ █████╗ ██████╗ ███████╗ █████╗ ██╗  ██╗███╗   ██╗${c_rst}"
  echo -e "${c_hot}  ██╔════╝██╔════╝██║  ██║██║    ██║██╔══██╗██╔══██╗╚══███╔╝██╔══██╗██║  ██║████╗  ██║${c_rst}"
  echo -e "${c_bld}  ███████╗██║     ███████║██║ █╗ ██║███████║██████╔╝  ███╔╝ ███████║███████║██╔██╗ ██║${c_rst}"
  echo -e "${c_bld}  ╚════██║██║     ██╔══██║██║███╗██║██╔══██║██╔══██╗ ███╔╝  ██╔══██║██╔══██║██║╚██╗██║${c_rst}"
  echo -e "${c_hot}  ███████║╚██████╗██║  ██║╚███╔███╔╝██║  ██║██║  ██║███████╗██║  ██║██║  ██║██║ ╚████║${c_rst}"
  echo -e "${c_sh}  ╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝${c_rst}"
  echo -e "  ${c_bold}${c_hot}by ${BRAND}${c_rst}  ${c_dim}${TOOL}${c_rst}"
  echo -e "  ${c_sh}$(printf '═%.0s' {1..64})${c_rst}"
}

match_suspicious() {
  local s
  s=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  case "$s" in
    *xclicker*|*autoclick*|*clicker*|*jnativehook*|*nativehook*|*triggerbot*|*aimassist*|*crystalpvp*|*wurst*|*meteor*|*impact*|*aristois*|*liquidbounce*|*baritone*)
      return 0 ;;
  esac
  return 1
}

banner

section "SYSTEM"
info "User: ${USER:-?}  Host: $(hostname 2>/dev/null || echo '?')"
info "Desktop: ${XDG_CURRENT_DESKTOP:-unknown}  Session: ${XDG_SESSION_TYPE:-?}"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  info "OS: ${PRETTY_NAME:-$NAME}"
fi
info "Now: $(date '+%Y-%m-%d %H:%M:%S %z')"

section "TMP / JNATIVEHOOK"
tmp_hits=0
if [[ -d /tmp ]]; then
  while IFS= read -r -d '' f; do
    base=$(basename "$f")
    if match_suspicious "$base" || echo "$base" | grep -qiE 'jnativehook|nativehook|libjnh|clicker|xclicker'; then
      bad "TMP: $f"
      tmp_hits=$((tmp_hits+1))
      ls -la --time-style=long-iso "$f" 2>/dev/null | sed 's/^/      /'
    fi
  done < <(find /tmp -maxdepth 3 -type f \( -iname '*jnativehook*' -o -iname '*nativehook*' -o -iname '*xclicker*' -o -iname '*clicker*' -o -iname '*.so' -o -iname '*.jar' \) -print0 2>/dev/null)
  if [[ $tmp_hits -eq 0 ]]; then
    ok "No obvious jnativehook/clicker traces in /tmp (depth 3)"
  fi
else
  warn "/tmp missing?"
fi

section "SUSPICIOUS PROCESSES"
proc_hits=0
while read -r pid cmd; do
  [[ -z "${cmd:-}" ]] && continue
  if match_suspicious "$cmd"; then
    bad "PROC $pid: $cmd"
    proc_hits=$((proc_hits+1))
  fi
done < <(ps -eo pid=,args= --no-headers 2>/dev/null || true)
# also common capture/remote
while read -r pid cmd; do
  low=$(echo "$cmd" | tr '[:upper:]' '[:lower:]')
  if echo "$low" | grep -qiE '\bobs\b|obs-studio|simplescreenrecorder|ffmpeg.*(x11grab|kmsgrab)|anydesk|rustdesk|teamviewer|parsec'; then
    warn "CAPTURE/REMOTE $pid: $cmd"
  fi
done < <(ps -eo pid=,args= --no-headers 2>/dev/null || true)
if [[ $proc_hits -eq 0 ]]; then
  ok "No obvious cheat/clicker process names"
fi
info "Tip: top / htop for live view (sudo apt install htop || sudo dnf install htop)"

section "SHELL HISTORY (suspicious lines)"
hist_files=("$HOME/.bash_history" "$HOME/.zsh_history" "$HOME/.local/share/fish/fish_history")
h_hits=0
for hf in "${hist_files[@]}"; do
  [[ -f "$hf" ]] || continue
  info "History file: $hf ($(wc -l < "$hf" 2>/dev/null || echo 0) lines)"
  while IFS= read -r line; do
    if echo "$line" | grep -qiE 'xclicker|autoclick|jnativehook|wget.*(clicker|cheat)|curl.*(clicker|cheat)|chmod \+x|appimage|flatpak install|wine .*exe|regedit|shred |wipe|history -c|unset HISTFILE'; then
      bad "HIST: $line"
      h_hits=$((h_hits+1))
    fi
  done < <(tail -n 400 "$hf" 2>/dev/null || true)
done
if [[ $h_hits -eq 0 ]]; then
  ok "No high-signal lines in recent history tails"
fi
info "Manual: history | less"

section "RECENT INSTALLERS / BINS (home, 14d)"
ext_hits=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  base=$(basename "$f")
  mtime=$(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
  if match_suspicious "$base"; then
    bad "[$mtime] $f"
    ext_hits=$((ext_hits+1))
  else
    info "[$mtime] $f"
  fi
done < <(find "$HOME" -type f \( \
  -iname '*.appimage' -o -iname '*.run' -o -iname '*.deb' -o -iname '*.tar.gz' -o -iname '*.jar' -o -iname '*.exe' \
  \) -mtime -14 2>/dev/null | head -n 80)
if [[ $ext_hits -eq 0 ]]; then
  ok "No suspicious-named installers in last 14d (still review list above)"
fi

section "FIND RECENT BY EXT (cwd-style global hint)"
info "Example manual cmd:"
echo -e "  ${c_dim}find \$HOME -type f -iname '*.jar' -printf '%T@ %TY-%Tm-%Td %TH:%TM %p\\n' 2>/dev/null | sort -nr | head${c_rst}"

section "WINE / REGEDIT"
if command -v wine >/dev/null 2>&1 || command -v wine64 >/dev/null 2>&1; then
  warn "Wine is installed"
  if command -v regedit >/dev/null 2>&1; then
    info "regedit binary present — check HKCU\\Console for exe stubs manually"
  else
    info "regedit command not in PATH (try: wine regedit)"
  fi
  wine_prefix="${WINEPREFIX:-$HOME/.wine}"
  if [[ -d "$wine_prefix" ]]; then
    info "WINEPREFIX: $wine_prefix"
    if [[ -d "$wine_prefix/drive_c/windows/system32" ]]; then
      info "Wine system32 exists"
    fi
  fi
else
  ok "Wine not found in PATH"
fi

section "HOSTS BYPASS (/etc/hosts)"
if [[ -r /etc/hosts ]]; then
  host_hits=0
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    if echo "$line" | grep -qiE 'anticheat|screen.?share|ss\.|banappeal|hypixel|minehut|cubecraft|badlion|lunarclient|modrinth|github\.com|discord'; then
      bad "HOSTS: $line"
      host_hits=$((host_hits+1))
    fi
  done < /etc/hosts
  if [[ $host_hits -eq 0 ]]; then
    ok "No obvious blocked SS/anticheat domains in /etc/hosts"
  fi
  info "Manual: sudo nano /etc/hosts   (or gedit)"
else
  warn "Cannot read /etc/hosts"
fi

section "INSTALLED PACKAGES (name hits)"
pkg_hits=0
if command -v dpkg >/dev/null 2>&1; then
  while read -r line; do
    bad "PKG: $line"
    pkg_hits=$((pkg_hits+1))
  done < <(dpkg -l 2>/dev/null | awk '/^ii/ {print $2,$3}' | grep -iE 'xclicker|autoclick|wine|playonlinux|bottles|obs-studio|anydesk|rustdesk|teamviewer' || true)
elif command -v rpm >/dev/null 2>&1; then
  while read -r line; do
    bad "PKG: $line"
    pkg_hits=$((pkg_hits+1))
  done < <(rpm -qa 2>/dev/null | grep -iE 'xclicker|autoclick|wine|bottles|obs-studio|anydesk|rustdesk|teamviewer' || true)
else
  warn "No dpkg/rpm — skip package dump"
fi
if [[ $pkg_hits -eq 0 ]]; then
  ok "No matching suspicious package names"
fi
info "Mint dump: dpkg -l > installed_apps.txt"

section "TRASH"
trash="$HOME/.local/share/Trash"
if [[ -d "$trash" ]]; then
  info "Trash path: $trash"
  ls -lt --time-style=long-iso "$trash" 2>/dev/null | head -n 15 | sed 's/^/      /'
  if [[ -d "$trash/files" ]]; then
    n=$(find "$trash/files" -mindepth 1 2>/dev/null | wc -l)
    info "Items in Trash/files: $n"
    find "$trash/files" -mindepth 1 -maxdepth 2 -printf '%TY-%Tm-%Td %TH:%TM  %p\n' 2>/dev/null | sort -r | head -n 20 | while read -r row; do
      if match_suspicious "$row"; then
        bad "TRASH: $row"
      else
        info "TRASH: $row"
      fi
    done
  fi
  warn "Compare Trash mtime with freeze time"
else
  ok "No Trash dir"
fi

section "USB DISCONNECTS (journal)"
if command -v journalctl >/dev/null 2>&1; then
  usb=$(journalctl -n 5000 --no-pager 2>/dev/null | grep -i disconnect | grep -i usb | tail -n 25 || true)
  if [[ -n "${usb:-}" ]]; then
    echo "$usb" | sed "s/^/      /"
    warn "Compare USB disconnect times with freeze"
  else
    ok "No recent usb disconnect lines in last journal slice"
  fi
else
  warn "journalctl not available"
fi

section "DESKTOP SEARCH / RECENT (Mint tip)"
info "Mint: Super key / menu search — try: clicker, autoclick, xclicker (rename often still hits)"
recent_dirs=(
  "$HOME/.local/share/recently-used.xbel"
  "$HOME/.local/share/RecentDocuments"
  "$HOME/.local/share/zeitgeist"
)
for rd in "${recent_dirs[@]}"; do
  if [[ -e "$rd" ]]; then
    info "Recent DB: $rd"
    if [[ -f "$rd" ]]; then
      grep -oiE 'file://[^"<]+' "$rd" 2>/dev/null | sed 's|file://||g;s|%20| |g' | tail -n 30 | while read -r u; do
        if match_suspicious "$u"; then
          bad "RECENT: $u"
        fi
      done
    fi
  fi
done

section "HIDDEN FILES TOGGLE"
desk=$(echo "${XDG_CURRENT_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')
info "Ctrl+H toggles hidden files in most file managers"
if echo "$desk" | grep -qi cinnamon; then
  info "Mint/Nemo show: gsettings set org.nemo.preferences show-hidden-files true"
  info "Hide again:     gsettings set org.nemo.preferences show-hidden-files false"
elif echo "$desk" | grep -qi gnome; then
  info "GNOME show: gsettings set org.gtk.Settings.FileChooser show-hidden true"
fi
info "Check ~/.anydesk ~/.minecraft ~/.tlauncher ~/.config etc."

section "VERDICT"
echo -e "  ${c_hot}hits=${hits}${c_rst}  ${c_warn}warns=${warns}${c_rst}"
if [[ $hits -ge 3 ]]; then
  echo -e "  ${c_bold}${c_hot}STRONG signals — dig manually (tmp/history/trash/usb).${c_rst}"
elif [[ $hits -ge 1 ]]; then
  echo -e "  ${c_warn}Some signals — verify against freeze time.${c_rst}"
else
  echo -e "  ${c_ok}No high-signal automated hits. Still do menu-search + manual review.${c_rst}"
fi

echo ""
echo -e "  ${c_bold}${c_hot}by ${BRAND}${c_rst}  ${c_dim}${TOOL}${c_rst}"
echo ""
