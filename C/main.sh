#!/bin/bash

### Defining constants and data directories we use for our scripts and storage. - Jon
WIKI_URL_LIST='https://en.wikipedia.org/wiki/List_of_municipalities_of_Norway'
# SCRIPT_DIR="$( pwd )"
# SCRIPT_DIR="$( dirname "$0" )"
TMP_DIR="${SCRIPT_DIR}/tmp"
UTIL_DIR="${SCRIPT_DIR}/utility_scripts"
LOGS_DIR="${SCRIPT_DIR}/logs"
DATA_DIR="${SCRIPT_DIR}/data"

### Importing our used utility script-files.
# source "${UTIL_DIR}/get_page.sh"
source "${UTIL_DIR}/html.sh"
source "${UTIL_DIR}/math.sh"



#########################################
###-- Task E - Municipalities table --###
#########################################

### Download the webpage to our local machine.
### I prefix the files with "step_x" to get them in order in the folder,
### and to simplify hunting for eventual errors. - Jon
curl -s https://en.wikipedia.org/wiki/List_of_municipalities_of_Norway > ./data/step_1_page_html.txt

### Removing whitespace characters (also tabs).
cat "./data/step_1_page_html.txt" | tr -d '\n\t' > "./data/step_2_page_one_line_html.txt"
### ^ "-d" stands for delete, deletes any of the following characters.

### Everything is on the same line; extracting our table in the third line (putting whitespace characters around it).
sed -E 's|<table class="sortable wikitable">|\n<table class="sortable wikipage">|' "./data/step_2_page_one_line_html.txt" |
    sed -E 's|(</table>)|</table>\1\n|g' > "./data/step_3_page_table_newline_html.txt"
### ^ sed stands for "string editor."
### ^ "-E" stands for extended syntax, but we might not actually need it here.

sed -n '3p' "./data/step_3_page_table_newline_html.txt" > "./data/step_4_table.txt"
### ^ "-n" stands for not printing the current line.

### Getting images to show up not only in the "live server" extension for VSC, but also in an open HTML-file.
### This is done by replacing the "//" with "https://" so opening the HTML-file will look on the internet for the images,
### rather than on our computer. Also creating a new intermediate file from the "step_4"-file to copy into. - Jon
sed -E 's|//upload|https://upload|g' "./data/step_4_table.txt" > "./data/step_5_table_with_images.txt"



#########################################################################
###-- Task C - Municipalities name, -link and -coordinate extractions --###
#########################################################################

### Using Aliaksei's code for extracting the relevant table parts, one municipality per line.
sed -E 's/.*<table class="sortable wikitable">(.*)<\/table>.*/\1/g' ./data/step_2_page_one_line_html.txt | sed 's/<\/table>/\n/g' |
    sed -n '1p' | grep -o '<tbody[ >].*<\/tbody>' | sed -E 's/<tbody[^>]*>(.*)<\/tbody>/\1/g' | sed -E 's/<tr[^>]*>//g' |
    sed 's/<\/tr>/\n/g' | sed -E 's/<td[^>]*>//g' | sed 's/<\/td>/\t/g' | sed '1d' > ./data/step_6_municipalities_info.txt

### 4 - cut the table, only take 2nd column (it contains <a> elements for each municipality)
cut -f 2 ./data/step_6_municipalities_info.txt > ./data/step_7_municipalities_extracted_info.txt

# 5 - extract the urls (from hrefs of <a>) and place names (the text inside <a>)
awk 'match($0, /href="[^"]*"/){url=substr($0, RSTART+6, RLENGTH-7)} match($0, />[^<]*<\/a>/){printf("%s%s\t%s\n",
    "https://en.wikipedia.org", url, substr($0, RSTART+1, RLENGTH-5))} ' ./data/step_7_municipalities_extracted_info.txt  > ./data/data.txt

# 6 - query individual-place URLs one by one; Takes long time -- watch 'data_with_coords.txt' for new data arriving in real time
truncate -s 0 ./data/data_with_coords.txt # if the file already exists, cut it down to zero bytes
while read url place; do
	pageHtml="$(curl -s "$url")"
	lat=$(echo $pageHtml | grep -o '<span class="latitude">[^<]*' | head -n 1 | sed 's/<span class="latitude">//' )
	lon=$(echo $pageHtml | grep -o '<span class="longitude">[^<]*' | head -n 1 | sed 's/<span class="longitude">//' )
	printf "%s\t%s\t%s\t%s\n" $url $place $lat $lon >> ./data/data_with_coords.txt
done < ./data/data.txt

# 7 - prettify data; convert URLs in href for <a>, wrap everything in paragraphs; "&#9;" is a "tab" character in HTML 
awk -F'\t' '{printf "<p><a href=\"%s\">%s</a> is here: <span>%s&#9;%s</span></p>\n", $1, $2, $3, $4 }' "data_with_coords.txt" > "pretty_data.html"

# 8 - render the page
sed -e '/<!--REPLACEME-->/r pretty_data.html' -e '/<!--REPLACEME-->/d' 'page_template.txt' > my_fancy_page.html



# awk '$name $page-link $population' "step_4_table.txt" > "municipality_data.txt"
### ^ "-n" stands for not printing the current line.

### Inserting a boilerplate HTML5 template here, with some light customization and additions.
page_template='
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="ie=edge">
        <title>Our fancy municipality information page</title>
        <link rel="stylesheet" href="style.css">
    </head>
    <body>
        <script src="index.js"></script>

        <header>
            <h1>My fancy municipality information page</h1>
            <p>By candidate number: 10079</p>
        </header>
        <hr>
        '"$(cat "./data/municipalities-table.txt")"'
    </body>
</html>
'

### Dumping variable contents in an HTML-file.
echo "$page_template" > "index.html"
