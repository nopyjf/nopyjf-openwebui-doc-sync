#!/bin/bash

# Stop on any error
set -e

# --- Configuration ---
# Load environment variables from .env file if it exists
if [ -f .env ]; then
  # Use `set -a` to export all variables created
  set -a
  source .env
  set +a
fi

# Check for required environment variables
if [ -z "$CONFLUENCE_DOMAIN" ] || [ -z "$CONFLUENCE_USERNAME" ] || [ -z "$CONFLUENCE_API_TOKEN" ]; then
    echo "Error: Please set CONFLUENCE_DOMAIN, CONFLUENCE_USERNAME, and CONFLUENCE_API_TOKEN."
    echo "You can create a .env file with these values."
    exit 1
fi

# --- Dependencies Check ---
for cmd in jq pandoc curl; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: Required command '$cmd' is not installed."
    echo "Please install it to continue."
    exit 1
  fi
done

# --- Main Script ---

# Create a directory to store the downloaded pages
OUTPUT_DIR="knowledges"
mkdir -p "$OUTPUT_DIR"

# Find Confluence page URLs in DOCS.md
# This regex is more specific to the common Confluence URL structure.
URLS=$(grep -o 'https://[a-zA-Z0-9.-]*/wiki/spaces/[a-zA-Z0-9]*/pages/[0-9]*/[^)]*' DOCS.md || true)

if [ -z "$URLS" ]; then
    echo "No Confluence page URLs found in DOCS.md."
    echo "Please add URLs in the format: https://domain/wiki/spaces/SPACE/pages/12345/Page-Title"
    exit 0
fi

echo "Found the following URLs to process:"
echo "$URLS"
echo "---"

# Process each URL
while IFS= read -r URL; do
    # Extract page ID from the URL. Handles URLs with or without trailing titles.
    PAGE_ID=$(echo "$URL" | sed -n 's|.*/pages/\([0-9]*\).*|\1|p')

    if [ -z "$PAGE_ID" ]; then
        echo "Warning: Could not extract Page ID from URL: $URL"
        continue
    fi

    echo "Processing Page ID: $PAGE_ID"

    # Construct the API URL
    API_URL="https://$CONFLUENCE_DOMAIN/wiki/rest/api/content/$PAGE_ID?expand=body.storage"

    # Fetch data from Confluence API
    # Using --fail to make curl exit with an error if the server returns an HTTP error code.
    RESPONSE=$(curl --silent --fail -u "$CONFLUENCE_USERNAME:$CONFLUENCE_API_TOKEN" "$API_URL")

    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data for Page ID $PAGE_ID from Confluence."
        continue
    fi

    # Extract title and HTML content
    TITLE=$(echo "$RESPONSE" | jq -r '.title')
    CONTENT_HTML=$(echo "$RESPONSE" | jq -r '.body.storage.value')

    # Sanitize the title to create a safe filename
    FILENAME=$(echo "$TITLE" | tr -cs 'a-zA-Z0-9_.' '-' | tr '[:upper:]' '[:lower:]').md
    # If the filename is empty (e.g., title was all special chars), use page ID
    if [ -z "$FILENAME" ] || [ "$FILENAME" = ".md" ]; then
        FILENAME="$PAGE_ID.md"
    fi

    echo "  -> Title: $TITLE"
    echo "  -> Saving to: $OUTPUT_DIR/$FILENAME"

    # Convert the Confluence Storage Format (which is XML/HTML-like) to Markdown
    # The `ac:structured-macro` and other Confluence-specific tags can be tricky.
    # Pandoc does a decent job with HTML, which is what storage format mostly is.
    echo "$CONTENT_HTML" | pandoc --from=html --to=markdown --wrap=none > "$OUTPUT_DIR/$FILENAME"

    if [ $? -eq 0 ]; then
        echo "  -> Successfully converted and saved."
    else
        echo "  -> Warning: pandoc conversion failed for Page ID $PAGE_ID. The raw HTML will be saved instead."
        echo "$CONTENT_HTML" > "$OUTPUT_DIR/$(basename "$FILENAME" .md).html"
    fi
    echo "---"

done <<< "$URLS"

echo "Script finished."
echo "Downloaded pages are in the '$OUTPUT_DIR' directory."
