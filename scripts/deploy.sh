#!/usr/bin/env bash
# JP Turtle testen und starten (macOS).
#
#   scripts/deploy.sh test                 Unit-Tests des Kerns (swift test)
#   scripts/deploy.sh sim                  im iOS-Simulator starten (keine Apple-ID nötig)
#   scripts/deploy.sh iphone               aufs angeschlossene iPhone installieren
#   scripts/deploy.sh xcode                Xcode-Projekt erzeugen und öffnen
#
# Option für sim/iphone/xcode:
#   --no-widget   ohne Widget-Extension bauen (Ausweg für xtool-Issue #313)
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-help}"
shift || true
NO_WIDGET=0
for arg in "$@"; do
  case "$arg" in
    --no-widget) NO_WIDGET=1 ;;
    *) echo "Unbekannte Option: $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m%s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mFehler: %s\033[0m\n' "$*" >&2; exit 1; }

need_mac()   { [[ "$(uname)" == "Darwin" ]] || fail "Dieses Skript ist für macOS gedacht. Für Linux/WSL siehe README."; }
need_xcode() {
  xcrun -sdk iphoneos --show-sdk-path >/dev/null 2>&1 \
    || fail "Kein iOS-SDK gefunden. Xcode installieren, einmal öffnen, dann: sudo xcode-select -s /Applications/Xcode.app"
}
need_xtool() {
  command -v xtool >/dev/null 2>&1 || fail "xtool fehlt. Installieren mit: brew install xtool-org/tap/xtool"
}
need_login() {
  if ! xtool auth status 2>/dev/null | grep -q "Logged in"; then
    say "Noch nicht bei Apple angemeldet – starte xtool setup"
    echo "Mit kostenloser Apple-ID im Menü '1: Password' wählen."
    xtool setup
  fi
}

bundle_id() { awk '/^bundleID:/ {print $2; exit}' xtool.yml; }

# Optional ohne Widget bauen: xtool.yml kurz ohne 'extensions:'-Block, danach Original zurück.
without_widget_if_requested() {
  [[ "$NO_WIDGET" == "1" ]] || return 0
  say "Baue ohne Widget-Extension (xtool.yml wird danach wiederhergestellt)"
  cp xtool.yml .xtool.yml.backup
  trap 'mv -f .xtool.yml.backup xtool.yml' EXIT
  awk '
    /^extensions:/ { skip = 1; next }
    skip && /^[^ #]/ { skip = 0 }
    !skip { print }
  ' .xtool.yml.backup > xtool.yml
}

case "$MODE" in
  test)
    say "Unit-Tests (JPTurtleCore)"
    swift test
    ;;

  sim)
    need_mac; need_xcode; need_xtool
    without_widget_if_requested
    if ! xcrun simctl list devices booted | grep -q "Booted"; then
      UDID="$(xcrun simctl list devices available | grep -m1 -E '^[[:space:]]+iPhone' | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
      [[ -n "$UDID" ]] || fail "Kein iPhone-Simulator gefunden. In Xcode unter Settings → Platforms die iOS-Simulatoren laden."
      say "Starte Simulator $UDID"
      xcrun simctl boot "$UDID" || true
    fi
    open -a Simulator
    say "Baue und installiere im Simulator"
    xtool dev run --simulator
    say "Starte JP Turtle"
    xcrun simctl launch booted "$(bundle_id)" || warn "Bitte die App im Simulator von Hand öffnen."
    ;;

  iphone)
    need_mac; need_xcode; need_xtool; need_login
    without_widget_if_requested
    say "Verbundene Geräte"
    xtool devices || true
    cat <<'TXT'

Checkliste fürs iPhone:
  1. iPhone per Kabel verbinden und entsperren, bei "Diesem Computer vertrauen?" auf Vertrauen tippen.
  2. Entwicklermodus an: Einstellungen → Datenschutz & Sicherheit → Entwicklermodus (danach Neustart).
  3. Nach der Installation: Einstellungen → Allgemein → VPN & Geräteverwaltung → deiner Apple-ID vertrauen.
TXT
    say "Baue, signiere und installiere (xtool dev)"
    xtool dev
    say "Fertig. Mit kostenloser Apple-ID läuft die App 7 Tage – danach dieses Skript erneut ausführen."
    ;;

  xcode)
    need_mac; need_xcode; need_xtool
    without_widget_if_requested
    say "Erzeuge Xcode-Projekt"
    OUT="$(xtool dev generate-xcode-project | tee /dev/stderr | sed -n 's/^Wrote to //p' | tail -1)"
    if [[ -n "$OUT" ]]; then
      open "$OUT"
      echo "In Xcode: oben das Team (deine Apple-ID) unter Signing & Capabilities wählen, Gerät auswählen, ▶ drücken."
    fi
    ;;

  *)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    ;;
esac
