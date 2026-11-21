#!/bin/bash
# Coswars (Mac) : mise à jour automatique, lancée par l'app avant chaque partie.
#   maj-mac.sh <jeu de l'app> <jeu installé>          avant l'ouverture du jeu
#   maj-mac.sh --watch <jeu de l'app> <jeu installé>  veilleur, en arrière-plan, tant que le jeu est ouvert
# 0. (16/11) Se met à jour lui-même : la dernière version de ce script est publiée sur le site (maj/maj-mac.sh) ; si elle
#    diffère, elle est gardée dans le dossier de Coswars et c'est elle qui fait le travail. Plus besoin de réinstaller l'app
#    pour corriger la mise à jour.
# 1. Installe le jeu contenu dans l'app s'il est plus récent que celui déjà installé.
# 2. Regarde sur le site si une version plus récente existe (liste maj/fichiers.txt publiée par deploy-web.sh) ;
#    si oui, télécharge seulement les fichiers qui ont changé, les vérifie, puis les met en place.
# 3. (16/11) Lance un veilleur qui refait l'étape 2 toutes les 2 minutes tant que le jeu est ouvert : le jeu voit la
#    nouvelle version (version.txt) et redémarre tout seul dès qu'on est dans les menus.
# Sans internet, ou si un téléchargement échoue, on garde la copie installée : le jeu se lance quand même.
# La progression ne bouge pas : elle est gardée par Chrome pour ce dossier, qui reste le même.
WATCH=0; [ "$1" = "--watch" ] && { WATCH=1; shift; }
SRC="$1"; DST="$2"
SUP="$HOME/Library/Application Support/Coswars"
BASE="${COSWARS_BASE:-https://guillaumerouretravail-creator.github.io/coswars/}"   # COSWARS_BASE : pour les essais
BASE2="${COSWARS_BASE2:-https://coswars.com/jeu/}"   # 09/11 : secours (panne de GitHub) ; la liste la plus récente gagne
PROFIL="--user-data-dir=$SUP/profil-chrome --kiosk"
newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }   # $1 plus récente que $2
sha() { shasum -a 1 "$1" | cut -d' ' -f1; }

# 0. ce script lui-même
if [ -z "$COSWARS_MAJ_CHAIN" ]; then
  mkdir -p "$SUP"; N="$SUP/maj-mac.new"
  if curl -fsS --max-time 6 -o "$N" "${BASE}maj/maj-mac.sh?t=$(date +%s)" 2>/dev/null || curl -fsS --max-time 6 -o "$N" "${BASE2}maj/maj-mac.sh?t=$(date +%s)" 2>/dev/null; then
    if head -1 "$N" | grep -q '^#!/bin/bash' && grep -q 'COSWARS-MAJ-FIN' "$N" && ! cmp -s "$N" "$0"; then
      mv -f "$N" "$SUP/maj-mac.sh"; [ $WATCH = 1 ] && set -- --watch "$SRC" "$DST"
      COSWARS_MAJ_CHAIN=1 exec /bin/bash "$SUP/maj-mac.sh" "$@"
    fi
  fi
  rm -f "$N"
fi

maj() {   # étape 2 ; $1 = 1 : sans voix (veilleur)
  local inst L L2 ALT B ver TMP h p r q
  inst=$(cat "$DST/version.txt" 2>/dev/null || echo 0)
  vof() { printf '%s\n' "$1" | awk -F'\t' '$1=="version"{print $2; exit}'; }
  B=$BASE
  L=$(curl -fsS --max-time 6 "${BASE}maj/fichiers.txt?t=$(date +%s)" 2>/dev/null)
  L2=$(curl -fsS --max-time 6 "${BASE2}maj/fichiers.txt?t=$(date +%s)" 2>/dev/null)
  if [ -n "$L2" ] && { [ -z "$L" ] || newer "$(vof "$L2")" "$(vof "$L")"; }; then L=$L2; ALT=$BASE; B=$BASE2; else ALT=$BASE2; fi
  [ -n "$L" ] || return 0
  ver=$(vof "$L")
  [ -n "$ver" ] && newer "$ver" "$inst" || return 0
  [ "$1" = 1 ] || say -v Thomas "Mise à jour de Coswars, version $ver. Un instant." >/dev/null 2>&1 &
  TMP=$(mktemp -d)
  while IFS=$'\t' read -r h p r; do
    [ "$h" = version ] || [ -z "$p" ] && continue
    [ -f "$DST/$p" ] && [ "$(sha "$DST/$p")" = "$h" ] && continue
    mkdir -p "$TMP/$(dirname "$p")"
    if ! { curl -fsS --max-time 120 -o "$TMP/$p" "$B$r" && [ "$(sha "$TMP/$p")" = "$h" ]; } && ! { curl -fsS --max-time 120 -o "$TMP/$p" "$ALT$r" && [ "$(sha "$TMP/$p")" = "$h" ]; }; then rm -rf "$TMP"; return 0; fi
  done <<< "$L"
  # index.html en dernier : le jeu ne redémarre qu'une fois tous les sons en place
  (cd "$TMP" && find . -type f ! -name index.html) | while read -r q; do mkdir -p "$DST/$(dirname "$q")"; mv -f "$TMP/$q" "$DST/$q"; done
  [ -f "$TMP/index.html" ] && mv -f "$TMP/index.html" "$DST/index.html"
  echo "$ver" > "$DST/version.txt"
  rm -rf "$TMP"
}

if [ $WATCH = 1 ]; then
  # attend que le jeu s'ouvre (une minute au plus), puis vérifie toutes les 2 minutes tant qu'il est ouvert
  for i in $(seq 1 60); do pgrep -f -- "$PROFIL" >/dev/null && break; sleep 1; done
  while pgrep -f -- "$PROFIL" >/dev/null; do sleep "${COSWARS_WATCH_S:-120}"; pgrep -f -- "$PROFIL" >/dev/null || break; maj 1; done
  exit 0
fi

# 1. jeu de l'app plus récent que la copie installée
inst=$(cat "$DST/version.txt" 2>/dev/null || echo 0)
app=$(cat "$SRC/version.txt" 2>/dev/null || echo 0)
if [ ! -f "$DST/index.html" ] || newer "$app" "$inst"; then
  rm -rf "$DST"; mkdir -p "$(dirname "$DST")"; cp -R "$SRC" "$DST"
fi
# 2. version publiée
maj 0
# 3. veilleur (un seul à la fois), détaché de l'app
pkill -f -- "maj-mac.sh --watch" 2>/dev/null
nohup /bin/bash "$0" --watch "$SRC" "$DST" </dev/null >/dev/null 2>&1 &
exit 0
# COSWARS-MAJ-FIN (repère : le script téléchargé est complet)
