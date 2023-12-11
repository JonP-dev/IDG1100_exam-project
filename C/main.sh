#!/bin/bash

### Defining constants and data directories we use for our scripts and storage. - Jon
WIKI_URL_LIST='https://en.wikipedia.org/wiki/List_of_municipalities_of_Norway'
# SCRIPT_DIR="$( pwd )"
# SCRIPT_DIR="$( dirname "$0" )"
TMP_DIR="${SCRIPT_DIR}/tmp"
UTIL_DIR="${SCRIPT_DIR}/utility_scripts"
LOGS_DIR="${SCRIPT_DIR}/logs"
DATA_DIR="${SCRIPT_DIR}/data"



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

### Inserting a boilerplate HTML5 template here, with some light customization and additions.
page_template_E='
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="ie=edge">
        <title>Our fancy municipality information page</title>
        <link rel="stylesheet" href="./styles/style.css">
    </head>
    <body>
        <script src="index.js"></script>

        <header>
            <h1>My fancy municipality information page</h1>
            <p>By candidate number: 10079</p>
        </header>
        <hr>
        '"$(cat "./data/step_5_table_with_images.txt")"'
    </body>
</html>
'

### Dumping variable contents in an HTML-file.
echo "$page_template_E" > "index.html"



###########################################################################
###-- Task C - Municipalities name-, link- and coordinate-extractions --###
###########################################################################

### Using Aliaksei's code for extracting the relevant table parts, one municipality per line.
sed -E 's/.*<table class="sortable wikitable">(.*)<\/table>.*/\1/g' ./data/step_2_page_one_line_html.txt | sed 's/<\/table>/\n/g' |
    sed -n '1p' | grep -o '<tbody[ >].*<\/tbody>' | sed -E 's/<tbody[^>]*>(.*)<\/tbody>/\1/g' | sed -E 's/<tr[^>]*>//g' |
    sed 's/<\/tr>/\n/g' | sed -E 's/<td[^>]*>//g' | sed 's/<\/td>/\t/g' | sed '1d' > ./data/step_6_municipalities_info.txt

### Cut the table to get the 2nd column.
cut -f 2 ./data/step_6_municipalities_info.txt > ./data/step_7_municipalities_extracted_info.txt

### Extracting the URLs (from hrefs of <a>) and place names (the text inside <a>).
awk 'match($0, /href="[^"]*"/){url=substr($0, RSTART+6, RLENGTH-7)} match($0, />[^<]*<\/a>/){printf("%s%s\t%s\n",
    "https://en.wikipedia.org", url, substr($0, RSTART+1, RLENGTH-5))} ' ./data/step_7_municipalities_extracted_info.txt  > ./data/data.txt

### Using Aliaksei's code for getting the coordinates (by querying individual-place URLs one by one),
### but in a function so we can make use of local variables. - Jon
function coordinate_getter {
    local municipality_iterator=0

    ### Here we replace the spaces temporarily with a weird special character or special character sequence instead for later replacement,
    ### as this makes the next function easier to get running right. - Jon
    sed -E "s/ /+/g" ./data/data.txt

    truncate -s 0 ./data/data_with_urls.txt ### If the files already exists, cut them down to zero bytes.
    truncate -s 0 ./data/data_with_coords.txt

    while read url place; do
        pageHtml="$(curl -s "$url")"
        lat=$(echo $pageHtml | grep -o '<span class="latitude">[^<]*' | head -n 1 | sed 's/<span class="latitude">//' )
        lon=$(echo $pageHtml | grep -o '<span class="longitude">[^<]*' | head -n 1 | sed 's/<span class="longitude">//' )
        
        ### Here we're only interested in the coordinate-data and not the URLs and placenames as we already have those in data.txt. - Jon
        # printf "%s\t%s\n" $url $place >> ./data/data_with_urls.txt
        printf "%s\t%s\n" $lat $lon >> ./data/data_with_coords.txt

        ### Added extra information regarding the ongoing process for the terminal window. - Jon
        ((municipality_iterator++))
        echo "Got municipality info $municipality_iterator/356, $place."

    done < ./data/data.txt

    ### Switching spaces back, just for tidying up. - Jon
    sed -E "s/+/ /g" ./data/data.txt
}
### Running the function.
coordinate_getter

### Adding run permission and running our coordinate utility script.
chmod +x ./utility_scripts/coordinate-splitter.sh
# bash ./utility_scripts/coordinate-splitter.sh

### Doing some coordinate-math (divide minutes by 60, seconds by 3600):


### Adding run permission and running our data-combiner utility script.
chmod +x ./utility_scripts/data-combiner.sh
# bash ./utility_scripts/data-combiner.sh

### Extracting latitude- and longitude-values into separate files
awk -F'\t' '{printf "<p><a href=\"%s\">%s</a> is here: <span>%s&#9;%s</span></p>\n",
    $1, $2, $3, $4 }' "./data/data_with_coords.txt" > "./data/data_with_coords_prettified.txt"

### Creating a table for easier population extraction, one row with columns each line. - Jon
# sed -E 's|</tr>|</tr>\n|g' "./data/step_5_table_with_images.txt" > "./data/table_rows_on_newlines.txt"

### Cutting table column number 5 for the population numbers only, a more effective solution than the above rows on newlines,
### and subsequent population extractions.
cut -f 5 ./data/step_5_table_with_images > ./data/population-info.txt

### Format the data better.
awk -F'\t' '{printf "<p><a href=\"%s\">%s</a> is here: <span>%s&#9;%s</span></p>\n",
    $1, $2, $3, $4 }' "./data/data_with_coords.txt" > "./data/data_with_coords_prettified.txt"

### Inserting a boilerplate HTML5 template here, with some light customization and additions.
page_template_C='
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
        '"$(cat "./data/data_with_coords_prettified.txt")"'
    </body>
</html>
'

### Dumping variable contents in an HTML-file.
# echo "$page_template_C" > "municipalities_with_coords.html"
