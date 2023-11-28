#!/bin/bash

function query_api(){
    local url date_updated
    url=$1
    date_updated=${2:-$(TZ=GMT date)}
    # make an API request; send if modified since
    curl -s -i \
        -H "Accept: application/xml" \
        -H "If-Modified-Since: ${date_updated}" \
        -H "User-Agent: ntnu.no aliaksei.miniukovich@ntnu.no teaching_bash_to_students" \
        "${url}"
}
