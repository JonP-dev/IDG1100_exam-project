#!/bin/bash

# requests a page, follwing redirects, and preps it for sed processing
function get_page(){
    local url fname html one_line_html
    url=$1
    fname=$2

    html="$(curl -s -L "$url")"

    # removing all newline and tab characters - so we can process the entire page as a single string -- because sed, awk, cut, and grep work line by line
    one_line_html="$( echo "$html" | tr -d '\n\t' )" 

    if [ -z "$fname" ]; then
        # returning the result as standard output
        echo "$one_line_html"
    else
        # a filename was supplied - saving the output in a file
        printf "%s" "$one_line_html" > "$fname"
    fi
    echo "We've received the page: ${url}" >&2
}

# extracts an html element from a string
# takes an html string as standard input
# NOTE: only works with paired tags (i.e., not <img/>)
function extract_elements(){
    local html_single_line tag attributes
    tag="$1"
    attributes="$2"
    html_single_line=''

    if [[ -n "${attributes}" ]]; then
        # a space between a tag and its attributes - let's hope the supplied HTML is proper HTML
        attributes=' '"$attributes"
    fi

    while read -r line; do
        html_single_line+=$line
    done

    # because awk, sed and grep all search for greedy matches, we'll use their working line-by-line to extract multiple elements (else it extracts between the 1st-element opening tag and last-element closing tag - not what we want)
    opening_tag="<${tag}${attributes}>"
    closing_tag="</${tag}>"

    echo "$html_single_line" | \
        sed -E "s|(${closing_tag})|\1\n|g" |\
        grep -o "${opening_tag}.*${closing_tag}"
}

function extract_selfclosing_elements(){
    local tag template html_single_line
    tag="$1"
    template="$2"

    while read -r line; do
        html_single_line+=$line
    done

    search_element="<${tag} ?${template} ?/?>"
    # ensuring each element occupies one line; then searching for the needed like (aka, element)
    html_multi_line=$(
        echo "$html_single_line" |\
            sed -E "s|(>)|\1\n|g" |\
            sed -E 's|(<)|\n\1|g' )
    sed '/^$/d' <<< "$html_multi_line" |\
        grep -E -o "${search_element}"
}

# takes an html element (or many elements) as a string (stdin) and extracts its contents (stdout)
function get_inner_html(){
    while read -r element; do
        # splitting the string on opening/closing tags
        by_line=$( echo "$element" | \
            sed -E "s|(<\/[[:alpha:]]+>)|\n\1\n|g" | \
            sed -E "s|(<[[:alpha:]][^>]*>)|\n\1\n|g")
        # removing empty lines, and the 1st and last lines; then pasting everything back in a single line
        res=$(sed '/^$/d' <<< "$by_line" | \
            sed '1d;$d' |\
            paste -s -d '')
        echo "$res"
    done
}

# takes html strings as input (stdin) and splits them on a specific tag - to create 'tables'
# NOTE: only works on paired tags
function tags2columns(){
    local split_on_tag delimiter
    split_on_tag="${1:-'td'}"
    delimiter="${2:-'\t'}"
    opening_tag="<${split_on_tag}[^>]*>"
    closing_tag="<\/${split_on_tag}>"
    while read -r html_string; do
        # also 1st making sure we remove all delimiter characters - so there aren't any accidental splits/columns
        echo "$html_string" |\
            tr -d "$delimiter" |\
            sed -E "s/(${opening_tag})|(${closing_tag})/${delimiter}/g" |\
            tr -s "$delimiter" |\
            sed -E "s|^\t||"
    done

    # echo "Split in columns on: ${split_on_tag}" >&2
}
