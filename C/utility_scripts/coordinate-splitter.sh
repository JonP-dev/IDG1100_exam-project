#!/bin/bash

DATA_DIR="${SCRIPT_DIR}../data"

function split_coordinates {
    ### Emptying files just in case.
    truncate -s 0 ../data/lat-file.txt
    truncate -s 0 ../data/lon-file.txt

    ### Splitting coordinates.
    awk '{print $1}' "../data/data_with_coords.txt" > "../data/lat-file.txt"
    awk '{print $2}' "../data/data_with_coords.txt" > "../data/lon-file.txt"
}
### Running the script.
split_coordinates

function character_removal {
    ### Removing special characters from coordinates:
    sed -E "s/A-Z//g" | sed -E "s/a-z//g" | sed -E "s/a-z//g" "$DATA_DIR/lat-file.txt"
    sed -E "s/A-Z//g" | sed -E "s/a-z//g" | sed -E "s/a-z//g" "$DATA_DIR/lon-file.txt"
}
### Running the script.
character_removal
