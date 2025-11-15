# Stop on any error
$ErrorActionPreference = "Stop"

# --- Configuration ---
# Check for required environment variables
$ConfluenceDomain = $env:CONFLUENCE_DOMAIN
$ConfluenceUsername = $env:CONFLUENCE_USERNAME
$ConfluenceApiToken = $env:CONFLUENCE_API_TOKEN

if ([string]::IsNullOrEmpty($ConfluenceDomain) -or [string]::IsNullOrEmpty($ConfluenceUsername) -or [string]::IsNullOrEmpty($ConfluenceApiToken)) {
    Write-Error "Please set CONFLUENCE_DOMAIN, CONFLUENCE_USERNAME, and CONFLUENCE_API_TOKEN environment variables."
    Write-Host "You can set them in your PowerShell session like this:"
    Write-Host '$env:CONFLUENCE_DOMAIN="your-domain.atlassian.net"'
    Write-Host '$env:CONFLUENCE_USERNAME="your-email@example.com"'
    Write-Host '$env:CONFLUENCE_API_TOKEN="your-api-token"'
    exit 1
}

# --- Dependencies Check ---
$pandocPath = Get-Command pandoc -ErrorAction SilentlyContinue
if (-not $pandocPath) {
    Write-Error "Pandoc could not be found. Please install it and ensure it's in your PATH."
    exit 1
}

# --- Main Script ---

# Create a directory to store the downloaded pages
$OutputDirectory = "knowledges"
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

# Find Confluence page URLs in README.md
$readmePath = "README.md"
$regex = 'https://[a-zA-Z0-9.-]*/wiki/spaces/[a-zA-Z0-9]*/pages/[0-9]*/[^)]*'
$urls = Get-Content $readmePath | Select-String -Pattern $regex -AllMatches | ForEach-Object { $_.Matches.Value }

if (-not $urls) {
    Write-Host "No Confluence page URLs found in README.md."
    Write-Host "Please add URLs in the format: https://domain/wiki/spaces/SPACE/pages/12345/Page-Title"
    exit 0
}

Write-Host "Found the following URLs to process:"
$urls | Write-Host
Write-Host "---"

# Create headers for authentication
$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ConfluenceUsername}:${ConfluenceApiToken}"))
}

# Process each URL
foreach ($url in $urls) {
    # Extract page ID from the URL
    $pageIdRegex = '(?<=/pages/)\d+'
    $pageId = [regex]::Match($url, $pageIdRegex).Value

    if ([string]::IsNullOrEmpty($pageId)) {
        Write-Warning "Could not extract Page ID from URL: $url"
        continue
    }

    Write-Host "Processing Page ID: $pageId"

    # Construct the API URL
    $apiUrl = "https://$ConfluenceDomain/wiki/rest/api/content/$pageId`?expand=body.storage"

    try {
        # Fetch data from Confluence API
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
    } catch {
        Write-Error "Failed to fetch data for Page ID $pageId from Confluence."
        Write-Error $_.Exception.Message
        continue
    }

    $title = $response.title
    $contentHtml = $response.body.storage.value

    # Sanitize the title to create a safe filename
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
    $sanitizedTitle = $title -replace "[$invalidChars]", '-' -replace '-+', '-'
    $filename = "$($sanitizedTitle.ToLower()).md"

    if ([string]::IsNullOrWhiteSpace($sanitizedTitle)) {
        $filename = "$pageId.md"
    }

    $outputPath = Join-Path -Path $OutputDirectory -ChildPath $filename

    Write-Host "  -> Title: $title"
    Write-Host "  -> Saving to: $outputPath"

    # Convert HTML to Markdown using pandoc
    try {
        $contentHtml | pandoc --from=html --to=markdown --wrap=none | Set-Content -Path $outputPath
        Write-Host "  -> Successfully converted and saved."
    } catch {
        Write-Warning "pandoc conversion failed for Page ID $pageId. The raw HTML will be saved instead."
        $htmlOutputPath = $outputPath -replace '\.md$', '.html'
        $contentHtml | Set-Content -Path $htmlOutputPath
    }
    Write-Host "---"
}

Write-Host "Script finished."
Write-Host "Downloaded pages are in the '$OutputDirectory' directory."
