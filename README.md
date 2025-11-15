# Confluence Pages Downloader

This repository contains scripts to download specified Confluence pages as Markdown files.

## Pages to Download

Add the Confluence pages you want to download to the list below. The script will parse this file to find them.

- https://your-domain.atlassian.net/spaces/12334/wiki/pages/123456

The scripts will:
1. Read the `README.md` file to find all Confluence page URLs.
2. Create a `knowledges` directory if it doesn't exist.
3. For each URL, it will call the Confluence API to fetch the page content.
4. Convert the page content from HTML to Markdown.
5. Save the result as a `.md` file in the `knowledges` directory.

---

### For Linux/macOS (Bash)

**Prerequisites:**

Before running the script, you need to have the following tools installed:
- `curl`
- `jq` (a lightweight and flexible command-line JSON processor)
- `pandoc` (a universal document converter)

On macOS, you can install them using [Homebrew](https://brew.sh/):
```bash
brew install jq pandoc
```

**Setup:**

1.  **Configure Environment Variables:**

    The script requires your Confluence domain, username, and an API token. The recommended way to provide them is by creating a `.env` file in the root of this project.

    Create a file named `.env` with the following content:
    ```
    CONFLUENCE_DOMAIN="your-domain.atlassian.net"
    CONFLUENCE_USERNAME="your-email@example.com"
    CONFLUENCE_API_TOKEN="your-api-token"
    ```

    - Replace `"your-domain.atlassian.net"` with your organization's Confluence domain.
    - Replace `"your-email@example.com"` with the email address you use to log in to Confluence.
    - Replace `"your-api-token"` with a valid Confluence API token. You can generate one from your Atlassian account settings: [Manage API tokens](https://id.atlassian.com/manage-profile/security/api-tokens).

2.  **Make the script executable:**
    ```bash
    chmod +x download_pages.sh
    ```

**Usage:**

Run the script from your terminal:
```bash
./download_pages.sh
```

---

### For Windows (PowerShell)

A PowerShell version of the script is available (`download_pages.ps1`).

**Prerequisites:**

- **PowerShell:** Comes pre-installed with modern Windows.
- **Pandoc:** You must install Pandoc and ensure it is available in your system's PATH. You can download it from the [Pandoc website](https://pandoc.org/installing.html).

**Setup:**

1.  **Configure Environment Variables:**

    Open a PowerShell terminal and set the following environment variables for your session. For a more permanent solution, you can add them to your PowerShell profile or set them in the System Environment Variables dialog.

    ```powershell
    $env:CONFLUENCE_DOMAIN="your-domain.atlassian.net"
    $env:CONFLUENCE_USERNAME="your-email@example.com"
    $env:CONFLUENCE_API_TOKEN="your-api-token"
    ```
    Replace the values with your own Confluence details.

2.  **Allow Script Execution:**

    By default, PowerShell may prevent running local scripts. You might need to change the execution policy for your current session.

    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    ```

**Usage:**

Run the script from your PowerShell terminal:
```powershell
.\download_pages.ps1
```
The script functions identically to the bash version, creating a `knowledges` directory and saving the converted Markdown files there.
