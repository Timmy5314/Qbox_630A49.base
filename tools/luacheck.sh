#!/usr/bin/env bash
# Syntaxcheck voor FiveM Lua.
#
# Standaard luac kent de CfxLua-uitbreidingen niet die deze codebase gebruikt:
#   `model`   backtick hash literal
#   ?. ?:     safe navigation
#   += -= *= /= ..=   compound assignment
#
# Dit script draait luac en beoordeelt zelf of een gemelde fout op zo'n regel
# staat. Alleen wat overblijft is een echte fout.
#
# Gebruik:
#   bash tools/luacheck.sh <bestand> [bestand...]
#   bash tools/luacheck.sh $(find "resources/[standalone]/los_anticheat" -name '*.lua')

LUAC="${LUAC:-/c/Users/timwi/AppData/Local/Programs/Lua/bin/luac}"

if [ ! -x "$LUAC" ] && ! command -v "$LUAC" >/dev/null 2>&1; then
    echo "luac niet gevonden op $LUAC. Zet LUAC= naar het juiste pad." >&2
    exit 2
fi

real_errors=0
checked=0
tmp="${TEMP:-/tmp}/luacheck_sanitized.lua"

# luac stopt bij de EERSTE fout. Simpelweg kijken of die regel een CfxLua-
# constructie bevat zou de rest van het bestand ongecontroleerd laten. Daarom
# maken we een gesaneerde kopie waarin de uitbreidingen zijn vervangen door
# equivalent standaard-Lua, en checken we die volledig.
#
# De compound-assignment regex eist een identifier-teken vóór de operator, zodat
# een comment als `--= foo` niet wordt aangetast.
sanitize() {
    # Backtick-hashes mogen elk teken bevatten behalve een backtick zelf:
    # `move_m@injured`, `a_m_m_bevhills_01`, `prop_ld_case_01`.
    # De eerdere versie accepteerde alleen [A-Za-z0-9_] en liet daardoor
    # alles met een @ erin staan, wat een valse "echte fout" opleverde.
    sed -e 's/`\([^`]*\)`/"\1"/g' \
        -e 's/?\./\./g' \
        -e 's/?:/:/g' \
        -e 's/\([A-Za-z0-9_)]\]*\)[[:space:]]*\.\.=/\1 =/g' \
        -e 's/\([A-Za-z0-9_)]\]*\)[[:space:]]*\([+*/-]\)=/\1 =/g' \
        "$1" > "$tmp"
}

for file in "$@"; do
    [ -f "$file" ] || continue
    checked=$((checked + 1))

    # Snelle weg: parseert het bestand meteen, dan zijn we klaar.
    "$LUAC" -p "$file" 2>/dev/null && continue

    sanitize "$file"
    out=$("$LUAC" -p "$tmp" 2>&1) && continue

    line=$(printf '%s' "$out" | sed -n 's/.*:\([0-9][0-9]*\): .*/\1/p' | head -1)

    echo "ECHTE FOUT  $file:${line:-?}"
    echo "            $(printf '%s' "$out" | sed "s|$tmp|$file|")"
    [ -n "$line" ] && echo "            $(sed -n "${line}p" "$file" | sed 's/^[[:space:]]*//')"
    real_errors=$((real_errors + 1))
done

rm -f "$tmp"

echo "---"
echo "$checked bestanden gecontroleerd, $real_errors echte fouten."
[ "$real_errors" -eq 0 ]
