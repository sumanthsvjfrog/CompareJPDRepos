# JPD Repository Comparison Tool

A high-efficiency automation suite designed to audit and compare repository states and configurations between two JFrog Platform Deployments (JPDs). This tool identifies discrepancies in **Local, Remote, and Virtual** repositories to ensure seamless environment parity.

## 🚀 Features

* **Storage & Count Audit:** Real-time tracking of file counts and used space for Local repositories.
* **Availability Mapping:** Flags repositories present in the Source JPD but missing in the Target.
* **Configuration Deep-Dive:**
    * **Remote:** Validates external URLs and checks for configured secrets.
    * **Virtual:** Compares member repository lists and deployment settings.
* **Adaptive API Engine:** Automatically detects and handles logic differences between Artifactory 6.x and 7.x.
* **Interactive Web Dashboard:** Built-in Python-based server for searchable, visual data analysis.

## 📋 Prerequisites

* **jq:** Required for JSON parsing.
* **curl:** Required for API communication.
* **python3:** Mandatory for serving the HTML Dashboard via the `weboutput` feature.

## 🛠️ Installation & Usage

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/your-username/jpd-repo-comparison.git](https://github.com/your-username/jpd-repo-comparison.git)
    cd jpd-repo-comparison
    ```

2. **Access Built-in Help: The script includes a help flag to provide a quick reference for arguments.**
    ```bash
    ./CompareJPDsRepoConfig_6x-7x.sh -h
    ```
2.  **Execute the Comparison:**
    Pass the credentials directly or via terminal variables for better security.
    ```bash
    ./CompareJPDsRepoConfig.sh <JPD_A_URL> <JPD_B_URL> <USER_A> <TOKEN_A> <USER_B> <TOKEN_B> yes
    ```
### 💡 Understanding the weboutput Argument:
* `yes`: The script will complete the analysis, launch a local Python web server on port 8000, and open the interactive dashboard in your browser. (Requires python3).
* `no`: The script generates all CSV reports and exits immediately without starting a server.

> **Note on Performance:** If the comparison involves an Artifactory **6.x** instance, the process will take more time. This is due to **architectural limitations** in Artifactory 6.x, which does not provide a direct API to retrieve all repository configurations in a single call. Consequently, the script must fetch details for each repository individually.

## 📊 Generated Reports

The tool generates a comprehensive set of CSV files for auditing and offline review:

### Local Repositories
* `local_repos_comparison.csv` (Full metrics: File counts, Used space)
* `only_in_source_local.csv`
* `only_in_target_local.csv`

### Remote Repositories
* `remote_repos_comparison.csv`
* `remote_repos_config_comparison.csv` (Target URL & Password verification)
* `only_in_source_remote.csv` / `only_in_target_remote.csv`

### Virtual Repositories
* `virtual_repos_comparison.csv`
* `virtual_repos_config_comparison.csv` (Member list & Deployment parity)
* `only_in_source_virtual.csv` / `only_in_target_virtual.csv`

## 📊 Consolidated Summary Reports
In addition to the granular audits, the tool generates two high-level consolidated files for a complete overview:

* `repo_comparision_consolidated.csv`: Combines existence and storage metrics for Local, Remote, and Virtual repositories into a single master list.

* `repo_comparision_config_consolidated.csv`: Merges all configuration delta data (URLs, passwords, member lists) for an all-in-one configuration audit.

## 🖥️ Dashboard Overview

When `weboutput` is set to **yes**, the script initiates a local server and opens an interactive dashboard.


### Key Interface Features:
* **Visual Status:** Missing repositories (e.g., `anilkt-project-npm-local`) are highlighted in **red** for immediate identification.
* **Search & Filter:** Built-in DataTables search allows you to filter through hundreds of entries by repository name or status instantly.
* **Config Delta Tracking:** The Configuration Comparison view tracks if member lists in Virtual repos differ, marked by a `DifferenceInRepos` flag.
* **Termination:** Simply return to your terminal and press `Ctrl+C` to shut down the web server when finished.

## 📁 Project Structure

```text
.
├── CompareJPDsRepoConfig.sh   # Main execution script
├── CompareJPDsRepoConfig.html       # Dashboard template
├── README.md                        # Documentation
└── .gitignore                       # Excludes temporary JSON/CSV data
