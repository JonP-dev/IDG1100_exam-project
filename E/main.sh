#!/bin/bash

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
