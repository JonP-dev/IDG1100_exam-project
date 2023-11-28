#!/bin/bash

### Download the webpge to our local machine.
curl -s https://en.wikipedia.org/wiki/List_of_municipalities_of_Norway > step_1_page.html.txt

### Removing whitespace characters (also tabs).
cat "step_1_page.html.txt" | tr -d '\n\t' > "step_2_page_one_line.html.txt"
### ^ "-d" stands for delete, deletes any of the following characters.

### Everything is on the same line; extracting our table in the third line (putting whitespace characters around it).
sed -E 's|<table class="sortable wikitable">|\n<table class="sortable wikipage">|' "step_2_page_one_line.html.txt" |
    sed -E 's|(</table>)|</table>\1\n|g' > "step_3_page_table_newline.html.txt"
### ^ sed stands for "string editor."
### ^ "-E" stands for extended syntax, but we might not actually need it here.

sed -n '3p' "step_3_page_table_newline.html.txt" > "step_4_table_only.txt"
### ^ "-n" stands for not printing the current line.

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
        '"$(cat "step_4_table_only.txt")"'
    </body>
</html>
'

### Dumping variable contents in a file.
echo "$page_template" > "table-page.html"
