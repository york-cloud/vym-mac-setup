#!/bin/zsh
# =============================================================================
#  ViewYork Media: Mac-Setup
#  Version 1.2, Stand 17.11.2026
#
#  Richtet einen frisch gestarteten Mac im ViewYork-Standard ein:
#  Programme, Dock, Screenshots, Scrollrichtung, Hintergrund- und Profilbild.
#  Läuft nach dem Einrichtungsassistenten im Benutzerkonto der neuen Person.
#
#  Aufruf:
#    zsh setup.sh                        kompletter Durchlauf
#    zsh setup.sh --name "VYM-Chrysler"  kompletter Durchlauf, setzt den Gerätenamen
#    zsh setup.sh --dock                 nur das Dock neu aufbauen (nach der
#                                        Chrome-Anmeldung, wenn die Web-Apps da sind)
#
#  Das Skript kann beliebig oft laufen. Bereits Installiertes wird übersprungen.
#  Es enthält keine Passwörter und meldet niemanden irgendwo an.
# =============================================================================

# ----------------------------- Einstellungen ---------------------------------
# Hier wird der ViewYork-Standard gepflegt. Alles Weitere unten liest von hier.

# Programme (Homebrew-Namen). Reihenfolge ist egal.
CASKS=(
  google-chrome
  slack
  notion
  keeper-password-manager
  google-drive
  claude
  claude-code
)

# Dock: Größe in Pixeln (klein im Ruhezustand, groß beim Überfahren)
DOCK_TILESIZE=40
DOCK_LARGESIZE=80
DOCK_SHOW_RECENTS=false     # "Zuletzt verwendete Programme" im Dock ausblenden

# Screenshots
SCREENSHOT_DIR="$HOME/Documents/Screenshots"

# GitHub-Ablage. Von hier lädt das Skript Hintergrund- und Profilbild,
# wenn sie nicht schon im Ordner "assets" neben dem Skript liegen.
GITHUB_KONTO="york-cloud"
GITHUB_REPO="vym-mac-setup"
GITHUB_BRANCH="main"

# Ablageorte der Bilder auf dem Mac
WALLPAPER_FILE="$HOME/Pictures/ViewYork/vym-hintergrund.png"
PROFILE_FILE="/Library/User Pictures/ViewYork/vym-profilbild.png"

# Ordner, in dem Chrome die Web-Apps (Gmail, Docs usw.) ablegt
WEBAPP_DIR="$HOME/Applications/Chrome Apps.localized"

LOGFILE="$HOME/Library/Logs/vym-mac-setup.log"

# ----------------------------- Hilfsfunktionen -------------------------------
MODE="full"
DEVICE_NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dock) MODE="dock" ;;
    --name) shift; DEVICE_NAME="$1" ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "Unbekannte Option: $1"; exit 1 ;;
  esac
  shift
done

mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

REPORT_OK=()
REPORT_OPEN=()

say_step() { printf "\n\033[1m== %s ==\033[0m\n" "$1"; }
ok()       { printf "  [ok]    %s\n" "$1"; REPORT_OK+=("$1"); }
open_item(){ printf "  [offen] %s\n" "$1"; REPORT_OPEN+=("$1"); }
info()     { printf "  %s\n" "$1"; }

# Sucht eine Web-App im Chrome-Apps-Ordner. Übergeben werden mögliche Namen,
# weil Chrome je nach Sprache anders benennt (z. B. "Sheets" oder "Tabellen").
find_webapp() {
  local name
  for name in "$@"; do
    if [ -d "$WEBAPP_DIR/$name.app" ]; then
      printf "%s" "$WEBAPP_DIR/$name.app"
      return 0
    fi
  done
  return 1
}

# Fügt einen Eintrag ins Dock ein, wenn die App existiert.
dock_add() {
  # Hinweis: die Variable darf in zsh nicht "path" heißen, das ist dort der Suchpfad
  local label="$1" target="$2"
  if [ -n "$target" ] && [ -e "$target" ]; then
    dockutil --add "$target" --no-restart >/dev/null 2>&1 && ok "Dock: $label" || open_item "Dock: $label ließ sich nicht hinzufügen"
  else
    open_item "Dock: $label fehlt noch (App nicht gefunden)"
  fi
}

# ----------------------------- Vorprüfungen ----------------------------------
echo ""
echo "ViewYork Media Mac-Setup, Version 1.2"
echo "Start: $(date '+%d.%m.%Y %H:%M') als Benutzer $(whoami)"

if [ "$(uname)" != "Darwin" ]; then
  echo "Dieses Skript läuft nur auf macOS."; exit 1
fi
if [ "$(id -u)" -eq 0 ]; then
  echo "Bitte ohne sudo starten. Das Skript fragt selbst nach dem Passwort."; exit 1
fi
if ! curl -fsI --max-time 10 https://github.com >/dev/null 2>&1; then
  echo "Keine Internetverbindung. Bitte WLAN prüfen und erneut starten."; exit 1
fi

if [ "$(uname -m)" = "arm64" ]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# ----------------------------- Dock aufbauen ---------------------------------
build_dock() {
  say_step "Dock"

  if ! command -v dockutil >/dev/null 2>&1; then
    open_item "dockutil fehlt, Dock wurde nicht angepasst"
    return
  fi

  defaults write com.apple.dock tilesize -int "$DOCK_TILESIZE"
  defaults write com.apple.dock largesize -int "$DOCK_LARGESIZE"
  defaults write com.apple.dock magnification -bool true
  defaults write com.apple.dock show-recents -bool "$DOCK_SHOW_RECENTS"

  dockutil --remove all --no-restart >/dev/null 2>&1

  # "Programme" heißt je nach macOS-Version Apps oder Launchpad
  local apps_overview="/System/Applications/Apps.app"
  [ -e "$apps_overview" ] || apps_overview="/System/Applications/Launchpad.app"

  # Feste Reihenfolge des ViewYork-Docks (der Finder steht immer ganz links)
  dock_add "Claude"              "/Applications/Claude.app"
  dock_add "Google Drive"        "/Applications/Google Drive.app"
  dock_add "Notion"              "/Applications/Notion.app"
  dock_add "Chrome"              "/Applications/Google Chrome.app"
  dock_add "Safari"              "/Applications/Safari.app"
  dock_add "Gmail"               "$(find_webapp "Gmail" "Google Mail")"
  dock_add "Slack"               "/Applications/Slack.app"
  dock_add "Google Docs"         "$(find_webapp "Google Docs" "Docs" "Google Dokumente" "Dokumente")"
  dock_add "Google Tabellen"     "$(find_webapp "Google Sheets" "Sheets" "Google Tabellen" "Tabellen")"
  dock_add "Google Präsentationen" "$(find_webapp "Google Slides" "Slides" "Google Präsentationen" "Präsentationen")"
  dock_add "Google Kalender"     "$(find_webapp "Google Calendar" "Calendar" "Google Kalender" "Kalender")"
  dock_add "Systemeinstellungen" "/System/Applications/System Settings.app"
  dock_add "Programme"           "$apps_overview"
  dock_add "App Store"           "/System/Applications/App Store.app"

  # Rechte Seite: Downloads-Ordner
  dockutil --add "$HOME/Downloads" --view fan --display stack --section others --no-restart >/dev/null 2>&1

  killall Dock >/dev/null 2>&1
  info "Dock neu gestartet."
}

if [ "$MODE" = "dock" ]; then
  [ -x "$BREW_PREFIX/bin/brew" ] && eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  build_dock
  say_step "Ergebnis"
  if [ ${#REPORT_OPEN[@]} -gt 0 ]; then
    echo "Noch offen:"; for item in "${REPORT_OPEN[@]}"; do echo "  - $item"; done
  else
    echo "Dock vollständig."
  fi
  exit 0
fi

# ----------------------------- Admin-Rechte ----------------------------------
say_step "Admin-Rechte"
info "Bitte das Mac-Passwort eingeben (die Eingabe bleibt unsichtbar)."
if ! sudo -v; then
  echo "Ohne Admin-Rechte kann das Skript nicht installieren. Abbruch."; exit 1
fi
# Hält die Berechtigung wach, bis das Skript endet
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT
ok "Admin-Rechte vorhanden"

# ----------------------------- Gerätename (optional) -------------------------
if [ -n "$DEVICE_NAME" ]; then
  say_step "Gerätename"
  HOST_SAFE="$(printf "%s" "$DEVICE_NAME" | tr ' ' '-' | tr -cd 'A-Za-z0-9-')"
  sudo scutil --set ComputerName "$DEVICE_NAME"
  sudo scutil --set LocalHostName "$HOST_SAFE"
  sudo scutil --set HostName "$HOST_SAFE"
  ok "Gerätename: $DEVICE_NAME"
fi

# ----------------------------- Homebrew --------------------------------------
say_step "Homebrew"
if [ ! -x "$BREW_PREFIX/bin/brew" ]; then
  info "Homebrew wird installiert. Das dauert einige Minuten."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ -x "$BREW_PREFIX/bin/brew" ]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  # Damit brew auch in künftigen Terminal-Fenstern gefunden wird
  if ! grep -q "brew shellenv" "$HOME/.zprofile" 2>/dev/null; then
    echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> "$HOME/.zprofile"
  fi
  ok "Homebrew bereit"
else
  open_item "Homebrew ließ sich nicht installieren. Skript bitte erneut starten."
  echo "Abbruch, weil ohne Homebrew keine Programme installiert werden können."
  exit 1
fi

# ----------------------------- Programme -------------------------------------
say_step "Programme"
for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    ok "$cask (bereits installiert)"
  else
    info "Installiere $cask ..."
    if brew install --cask "$cask"; then
      ok "$cask"
    else
      open_item "$cask ließ sich nicht installieren"
    fi
  fi
done

if brew list dockutil >/dev/null 2>&1 || brew install dockutil; then
  ok "dockutil"
else
  open_item "dockutil ließ sich nicht installieren"
fi

# ----------------------------- Systemeinstellungen ---------------------------
say_step "Systemeinstellungen"

mkdir -p "$SCREENSHOT_DIR"
defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"
killall SystemUIServer >/dev/null 2>&1
if [ "$(defaults read com.apple.screencapture location 2>/dev/null)" = "$SCREENSHOT_DIR" ]; then
  ok "Screenshots landen in Dokumente, Ordner Screenshots"
else
  open_item "Screenshot-Ordner ließ sich nicht setzen"
fi

defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
ok "Natürliches Scrollen aus (greift nach Ab- und Anmelden)"

# ----------------------------- Hintergrund und Profilbild --------------------
say_step "Hintergrund und Profilbild"

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
ASSET_URL="https://raw.githubusercontent.com/$GITHUB_KONTO/$GITHUB_REPO/$GITHUB_BRANCH/assets"
ASSET_TMP="$(mktemp -d)"

# Holt ein Bild: zuerst aus dem Ordner "assets" neben dem Skript, sonst von GitHub.
fetch_asset() {
  local file="$1"
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/assets/$file" ]; then
    cp "$SCRIPT_DIR/assets/$file" "$ASSET_TMP/$file"
  elif [ "$GITHUB_KONTO" != "HIER-EINTRAGEN" ]; then
    curl -fsSL --max-time 180 -o "$ASSET_TMP/$file" "$ASSET_URL/$file"
  else
    return 1
  fi
  [ -s "$ASSET_TMP/$file" ]
}

# Hintergrundbild (der Sperrbildschirm übernimmt es automatisch)
if fetch_asset "vym-hintergrund.png"; then
  mkdir -p "$(dirname "$WALLPAPER_FILE")"
  cp "$ASSET_TMP/vym-hintergrund.png" "$WALLPAPER_FILE"
  brew list --cask desktoppr >/dev/null 2>&1 || brew install --cask desktoppr >/dev/null 2>&1
  DESKTOPPR="$(command -v desktoppr 2>/dev/null || echo /usr/local/bin/desktoppr)"
  if [ -x "$DESKTOPPR" ] && "$DESKTOPPR" "$WALLPAPER_FILE" >/dev/null 2>&1; then
    ok "Hintergrundbild gesetzt"
  elif osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$WALLPAPER_FILE\"" >/dev/null 2>&1; then
    ok "Hintergrundbild gesetzt"
  else
    open_item "Hintergrundbild liegt unter Bilder, Ordner ViewYork, ließ sich aber nicht automatisch setzen"
  fi
else
  open_item "Hintergrundbild nicht gefunden (weder neben dem Skript noch auf GitHub)"
fi

# Profilbild des Benutzerkontos
if fetch_asset "vym-profilbild.png"; then
  sudo mkdir -p "$(dirname "$PROFILE_FILE")"
  sudo cp "$ASSET_TMP/vym-profilbild.png" "$PROFILE_FILE"
  sudo chmod 644 "$PROFILE_FILE"
  ME="$(whoami)"
  sudo dscl . -delete "/Users/$ME" JPEGPhoto >/dev/null 2>&1
  sudo dscl . -delete "/Users/$ME" Picture >/dev/null 2>&1
  if sudo dscl . -create "/Users/$ME" Picture "$PROFILE_FILE"; then
    ok "Profilbild gesetzt (sichtbar nach Ab- und Anmelden)"
  else
    open_item "Profilbild ließ sich nicht setzen. Datei liegt unter $PROFILE_FILE"
  fi
else
  open_item "Profilbild nicht gefunden (weder neben dem Skript noch auf GitHub)"
fi
rm -rf "$ASSET_TMP"

# ----------------------------- Dock ------------------------------------------
build_dock

# ----------------------------- Statusprüfungen -------------------------------
say_step "Prüfungen"

if fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
  ok "FileVault ist eingeschaltet"
else
  open_item "FileVault ist aus. Bitte in den Systemeinstellungen unter Datenschutz und Sicherheit einschalten und den Schlüssel im Keeper ablegen"
fi

if softwareupdate -l 2>&1 | grep -q "No new software available"; then
  ok "macOS ist aktuell"
else
  open_item "macOS-Update verfügbar. Bitte in den Systemeinstellungen installieren"
fi

if command -v claude >/dev/null 2>&1; then
  ok "Claude Code im Terminal verfügbar (Befehl: claude)"
else
  open_item "Claude Code ist im Terminal nicht auffindbar"
fi

# ----------------------------- Abschlussbericht ------------------------------
say_step "Ergebnis"
echo "Erledigt: ${#REPORT_OK[@]} Punkte"
if [ ${#REPORT_OPEN[@]} -gt 0 ]; then
  echo ""
  echo "Noch offen aus diesem Durchlauf:"
  for item in "${REPORT_OPEN[@]}"; do echo "  - $item"; done
fi

cat <<'EOF'

Nächste Schritte (Schritt 4 im Ablauf):
  1. Einmal ab- und wieder anmelden, damit Scrollrichtung und Profilbild greifen.
  2. Chrome öffnen und mit dem neuen ViewYork-Konto anmelden.
     Erweiterungen und Google-Web-Apps kommen dann per Richtlinie.
  3. Dieses Skript mit der Option --dock erneut starten.
     Dann rücken Gmail, Docs, Tabellen, Präsentationen und Kalender ins Dock.
  4. Claude öffnen, mit dem neuen Konto anmelden, Onboarding-Auftrag starten.

Von Hand zu erledigen (per Befehl nicht zuverlässig setzbar):
  - Automatische Helligkeit aus: Systemeinstellungen, Displays
  - Schreibtisch-Widgets: nur Wetter stehen lassen
  - Chrome als Standardbrowser bestätigen (macOS fragt nach)

EOF
echo "Protokoll: $LOGFILE"
echo "Ende: $(date '+%d.%m.%Y %H:%M')"
