#!/bin/bash

WEATHER_API_URL='https://api.met.no/weatherapi/locationforecast/2.0/classic?altitude=90'
# SCRIPT_DIR="$( pwd )"
# SCRIPT_DIR="$( dirname "$0" )"
TMP_DIR="${SCRIPT_DIR}/tmp"
UTIL_DIR="${SCRIPT_DIR}/utilities"
LOGS_DIR="${SCRIPT_DIR}/logs"
DATA_DIR="${SCRIPT_DIR}/data"


# loading our utilities
source "${UTIL_DIR}/api.sh"
source "${UTIL_DIR}/html.sh"

# for each record (aka, place), request/save the weather - expiresAt field doesn't exist or larger than time now
data_file="$DATA_DIR/places.txt"
# just in case this script is run simultaneously several times (due to crontab and script taking very long), we'll save output in a uniquely-named temporary file, and then move it's contents at once in the main file: places.txt - this way outputs from different runs won't get intermingled
tmp_out_file="$TMP_DIR/tmp.places.$RANDOM.txt"
while IFS=$'\t' read -r url place lat lon t rain date_for date_updated date_expires; do
    # if date_expires is empty, set it to now to make sure the script runs
    if [[ -z "$date_expires" ]]; then
        date_expires=$(date +'%s')
    fi
    # if date_expires is >= than time now, request fresh data
    date_now=$(date +'%s')
    if ((date_now >= date_expires)); then
        api_url="$WEATHER_API_URL""&lat=${lat}&lon=${lon}"
        # if date_updated isn't empty, use it; else use date_now
        if [[ -z "$date_updated" ]]; then
            date_updated=$(TZ=GMT date)
        fi
        # # make an API request; send if modified since
        # http_response=$(curl -s -i \
        #     -H "Accept: application/xml" \
        #     -H "If-Modified-Since: ${date_updated}" \
        #     -H "User-Agent: ntnu.no aliaksei.miniukovich@ntnu.no teaching_bash_to_students" \
        #     "${api_url}")
        http_response=$(query_api "$api_url" "$date_updated")
        head=$(sed '/^[[:space:]]*$/q' <<< "$http_response")
        body=$(sed '1,/^[[:space:]]*$/d' <<< "$http_response" | tr -d '\n\t')
        # check if 200
        status=$(head -n 1 <<< "$head" | cut -d' ' -f2)
        if ((status >= 200 && status < 300)); then
            # save new data
            date_for=$(date -d "tomorrow" +"%Y-%m-%d")'T12:00:00Z'
            time_elements=$(extract_elements "time" "datatype=\"forecast\" from=\"${date_for}\"[^>]*" <<< "$body")
            t=$(\
                echo "$time_elements" |\
                    extract_selfclosing_elements "temperature" '[^>\/]*' |\
                    head -n 1 |\
                    sed -E 's|.*value="([^"]*)".*|\1|' )
            rain=$(\
                echo "$time_elements" |\
                    extract_selfclosing_elements "precipitation" '[^>\/]*' |\
                    head -n 1 |\
                    sed -E 's|.*value="([^"]*)".*|\1|' )
            # update 'date_updated' and "date_expires"
            date_updated=$(grep -i "^date:" <<< "$head" | cut -d' ' -f2-)
            date_expires=$(grep -i "^expires:" <<< "$head"| cut -d' ' -f2-)
            echo "[LOG] $date_now 200 received fresh data for $place, rain: $rain, t: $t" >> "${LOGS_DIR}/logs.txt"
        elif ((status == 304)); then
            echo "[LOG] $date_now 304 no fresh data for $place" >> "${LOGS_DIR}/logs.txt"
        else
            # record errors
            echo "[ERROR] $date_now $(head -n 1 <<< "$head")" >> "${LOGS_DIR}/logs.txt"
        fi
    fi
    
    # record all updated values in a temporary file
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$url" "$place" "$lat" "$lon" "$t" "$rain" "$date_for" "$date_updated" "$date_expires" >> "$tmp_out_file"
done < "$data_file"

# move TMP FILE at once at completion
mv "${tmp_out_file}" "${data_file}"

# TODO: throttle requests?