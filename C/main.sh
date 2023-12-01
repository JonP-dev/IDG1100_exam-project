#!/bin/bash

# defining constants
WIKI_URL_LIST='https://en.wikipedia.org/wiki/List_of_municipalities_of_Norway'
# SCRIPT_DIR="$( pwd )"
# SCRIPT_DIR="$( dirname "$0" )"
TMP_DIR="${SCRIPT_DIR}/tmp"
UTIL_DIR="${SCRIPT_DIR}/utility_scripts"
LOGS_DIR="${SCRIPT_DIR}/logs"
DATA_DIR="${SCRIPT_DIR}/data"

# importing our utilities
# source "${UTIL_DIR}/get_page.sh"
source "${UTIL_DIR}/html.sh"
source "${UTIL_DIR}/math.sh"

### Extracting coordinates is slow - not re-running it if we already have the data.
if [[ ! -f  "${DATA_DIR}/places.txt" ]]; then

    # extracting places and URLs to per-place Wiki pages -- as <a> elements
    # # cat "${TMP_DIR}/1.html"|\
    get_page "$WIKI_URL_LIST" |\
        extract_elements 'table' 'class="sortable wikitable"' |\
        extract_elements 'tr' |\
        sed '1d' |\
        get_inner_html |\
        tags2columns 'td' '\t' |\
        cut -d $'\t' -f 2 > "$TMP_DIR/places_as_text.txt"

    # extracting URLs and places as data
    awk '
        match($0, /href="[^"]*"/){
                url=substr($0, RSTART+6, RLENGTH-7)
            }
        match($0, />[^<]*<\/a>/){
                printf("%s%s\t%s\n", "https://en.wikipedia.org", url, substr($0, RSTART+1, RLENGTH-5))
            } ' "$TMP_DIR/places_as_text.txt"  > "$TMP_DIR/places_as_data.txt"
    echo "Extracted places as data"

    # getting place coordinates per place
    truncate -s 0 "$TMP_DIR/places_with_coords.txt"
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
        printf "%s\t%s\t%s\t%s\n" $url $place $lat $lon >> "$TMP_DIR/places_with_coords.txt"
    done < "$TMP_DIR/places_as_data.txt"

    # converting the table with coordinates in a table with also API data (with empty values 1st)
    # adding 4 fields: temperature, precipitation, forecastDateFor, lastUpdated, expiresAt
    awk -F '\t' '
        {
            printf("%s\t\t\t\t\t\n", $0)
        }
    ' "$TMP_DIR/places_with_coords.txt" > "$DATA_DIR/places.txt"
fi

### Download the webpage to our local machine.
### I prefix the files with "step_x" to get them in order in the folder,
### and to simplify hunting for eventual errors. - Jon
curl -s https://en.wikipedia.org/wiki/List_of_municipalities_of_Norway > step_1_page_html.txt

### Removing whitespace characters (also tabs).
cat "step_1_page_html.txt" | tr -d '\n\t' > "step_2_page_one_line_html.txt"
### ^ "-d" stands for delete, deletes any of the following characters.

### Everything is on the same line; extracting our table in the third line (putting whitespace characters around it).
sed -E 's|<table class="sortable wikitable">|\n<table class="sortable wikipage">|' "step_2_page_one_line_html.txt" |
    sed -E 's|(</table>)|</table>\1\n|g' > "step_3_page_table_newline_html.txt"
### ^ sed stands for "string editor."
### ^ "-E" stands for extended syntax, but we might not actually need it here.

sed -n '3p' "step_3_page_table_newline_html.txt" > "step_4_table.txt"
### ^ "-n" stands for not printing the current line.

### Getting images to show up not only in the "live server" extension for VSC, but also in an open HTML-file.
### This is done by replacing the "//" with "https://" so opening the HTML-file will look on the internet for the images,
### rather than on our computer. Also creating a new intermediate file from the "step_4"-file to copy into. - Jon
sed -E 's|//upload|https://upload|g' "step_4_table.txt" > "step_5_table_with_images.txt"

### Inserting a boilerplate HTML5 template here, with some light customization and additions.
page_template='
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="ie=edge">
        <title>Our fancy municipalities table</title>
        <link rel="stylesheet" href="style.css">
    </head>
    <body>
        <script src="index.js"></script>

        <h1>My fancy municipalities table</h1>
        <hr>
        '"$(cat "step_5_table_with_images.txt")"'
    </body>
</html>
'

### Dumping variable contents in an HTML-file.
echo "$page_template" > "table-page.html"
