JPD Repository Comparison Tool
A high-efficiency automation suite designed to audit and compare repository states between two JFrog Platform Deployments (JPDs). This tool identifies discrepancies in Local, Remote, and Virtual repositories to ensure seamless environment parity.

🚀 Features
Storage & Count Audit: Provides real-time tracking of existence, file counts, and used space for Local repositories.

Availability Mapping: Flags repositories present in the Source JPD but missing in the Target JPD across all repository types.

Configuration Deep-Dive:

Remote: Validates external Target URLs and detects if authentication passwords/secrets are configured.

Virtual: Compares member repository lists and identifies differences in default deployment settings.

Adaptive API Engine: Automatically handles internal logic differences between Artifactory 6.x and 7.x.

Interactive Web Dashboard: Includes a built-in Python-based web server to launch a searchable, sortable HTML interface for immediate visual analysis.

📋 Prerequisites
jq: Required for processing JSON data from JFrog APIs.

curl: Required for secure API communication.

python3: Mandatory to serve the HTML Dashboard via the weboutput feature.

🛠️ Installation & Usage
Clone the repository:

Bash
git clone https://github.com/your-username/jpd-repo-comparison.git
cd jpd-repo-comparison
Run the comparison script:

Bash
./CompareJPDsRepoConfig_6x-7x.sh <JPD_A_URL> <JPD_B_URL> <SOURCE_USER> <SOURCE_TOKEN> <TARGET_USER> <TARGET_TOKEN> yes

Note on Performance: If the comparison involves an Artifactory 6.x instance, the process will take more time. This is due to architectural limitations in Artifactory 6.x, which does not provide a direct API to retrieve all repository configurations in a single call. Consequently, the script must fetch details for each repository individually.

📊 Generated Reports
The tool generates a comprehensive set of CSV files for auditing and offline review:

Local Repositories
local_repos_comparison.csv (Full metrics)

only_in_source_local.csv

only_in_target_local.csv

Remote Repositories
remote_repos_comparison.csv

remote_repos_config_comparison.csv (URL & Secret verification)

only_in_source_remote.csv / only_in_target_remote.csv

Virtual Repositories
virtual_repos_comparison.csv

virtual_repos_config_comparison.csv (Member list & Deployment parity)

only_in_source_virtual.csv / only_in_target_virtual.csv

🖥️ Dashboard Overview
When weboutput is set to yes, the script initiates a local server and opens the interactive dashboard.

Key Interface Features:
Visual Highlights: Rows highlighted in red (as seen with anilkt-project-npm-local) immediately signal repositories that do not exist in the Target JPD.

Search & Filter: Built-in DataTables search allows you to filter 360+ entries by repository name or status instantly.

Config Delta Tracking: The Configuration Comparison view (as shown below) tracks if member lists in Virtual repos differ, marked by a DifferenceInRepos flag.

Termination: Simply return to your terminal and press Ctrl+C to shut down the web server.



