#!/bin/bash

data_file="${SCRIPT_DIR}/data/places.txt"

# creating a static index page; reuses global variables to the current folder; requires places.txt to exist
function create_index_page(){
    local body title
    title="My Fancy Norway Weather Website"
    body=$(
        awk -F '\t' '
        {
            printf("<p>Weather for: <a href='/place.sh?place=%s'>%s</a></p>\n", $2, $2)
        }' "$data_file"
    )
    body="<h1>List of weather pages for places in Norway</h1>""$body"

    html=$(sed "s|%PageTitle%|${title}|" "${RESOURCE_DIR}/template.html")
    echo "${html//%body%/${body}}"
        # sed "s|%body%|${body}|"
    # echo "${RESOURCE_DIR}/template.html" >&2
}

function create_dynamic_page(){
    file=$(sed "s|%full_data_file_path%|${data_file}|" "${RESOURCE_DIR}/dynamic.page.sh.txt")
    # echo "$file" >&2
    echo "${file//%page_template%/$(cat "${RESOURCE_DIR}"/template.html)}"
        # sed "s|%page_template%|$(cat "${RESOURCE_DIR}"/template.html)|"
}

# url place lat lon t rain date_for date_updated date_expires

# copy from a dev location to an Apache-accessible location (/var/www)
sudo rm -rf "$DEST_DIR"
sudo mkdir -p "$DEST_DIR"
sudo cp -af "${RESOURCE_DIR}/favicons" "$DEST_DIR/favicons"
sudo cp "${RESOURCE_DIR}/main.css" "$DEST_DIR/main.css"
create_index_page | sudo tee "$DEST_DIR/index.html" > /dev/null
create_dynamic_page | sudo tee "$DEST_DIR/place.sh" > /dev/null

# change file ownership to www-data
sudo chown -R www-data:www-data "$DEST_DIR"

# make sure executable files are executable
sudo chmod +x "${DEST_DIR}/place.sh"