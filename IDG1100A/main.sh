#!/bin/bash

# defining constants
WIKI_URL_LIST='https://en.wikipedia.org/wiki/List_of_municipalities_of_Norway'
# SCRIPT_DIR="$( pwd )"
# SCRIPT_DIR="$( dirname "$0" )"
TMP_DIR="${SCRIPT_DIR}/tmp"
UTIL_DIR="${SCRIPT_DIR}/utilities"
LOGS_DIR="${SCRIPT_DIR}/logs"
DATA_DIR="${SCRIPT_DIR}/data"

# importing our utilities
# source "${UTIL_DIR}/get.page.sh"
source "${UTIL_DIR}/html.sh"
source "${UTIL_DIR}/math.sh"

# extracting coordinates is slow - not re-running it if we already have the data
if [[ ! -f  "${DATA_DIR}/places.txt" ]]; then

    # extracting places and URLs to per-place Wiki pages -- as <a> elements
    # # cat "${TMP_DIR}/1.html"|\
    get_page "$WIKI_URL_LIST" |\
        extract_elements 'table' 'class="sortable wikitable"' |\
        extract_elements 'tr' |\
        sed '1d' |\
        get_inner_html |\
        tags2columns 'td' '\t' |\
        cut -d $'\t' -f 2 > "$TMP_DIR/places.as.a.txt"

    # extracting URLs and places as data
    awk '
        match($0, /href="[^"]*"/){
                url=substr($0, RSTART+6, RLENGTH-7)
            }
        match($0, />[^<]*<\/a>/){
                printf("%s%s\t%s\n", "https://en.wikipedia.org", url, substr($0, RSTART+1, RLENGTH-5))
            } ' "$TMP_DIR/places.as.a.txt"  > "$TMP_DIR/places.as.data.txt"
    echo "Extracted places as data"

    # getting place coordinates per place
    truncate -s 0 "$TMP_DIR/places.with.coords.txt"
    while read -r url place; do
        page=$(get_page "$url")
        lat=$(extract_elements 'span' 'class="latitude"' <<< "$page" |\
            head -n 1 |\
            get_inner_html |\
            deg2dec)
        lon=$(extract_elements 'span' 'class="longitude"' <<< "$page" |\
            head -n 1 |\
            get_inner_html |\
            deg2dec)
        printf "%s\t%s\t%s\t%s\n" $url $place $lat $lon >> "$TMP_DIR/places.with.coords.txt"
    done < "$TMP_DIR/places.as.data.txt"

    # converting the table with coordinates in a table with also API data (with empty values 1st)
    # adding 4 fields: temperature, precipitation, forecastDateFor, lastUpdated, expiresAt
    awk -F '\t' '
        {
            printf("%s\t\t\t\t\t\n", $0)
        }
    ' "$TMP_DIR/places.with.coords.txt" > "$DATA_DIR/places.txt"
fi

# awk -F '\t' '
#     {
#         printf("%s\t\t\t\t\t\n", $0);
#         if(NR < FNR) printf("\n");
#     }
# ' "$TMP_DIR/places.with.coords.txt" | tail -n 4 > "$DATA_DIR/places.txt"
