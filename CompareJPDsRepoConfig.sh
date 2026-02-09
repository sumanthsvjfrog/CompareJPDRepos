#!/bin/bash

###Declaring variables
JPD_A_URL="$1"
JPD_B_URL="$2"
SOURCE_USER_NAME="$3"
SOURCE_AUTH_TOKEN="$4"
TARGET_USER_NAME="$5"
TARGET_AUTH_TOKEN="$6"
WEB_OUTPUT="${7:-no}"

SOURCE_AUTH="${SOURCE_USER_NAME}:${SOURCE_AUTH_TOKEN}"
TARGET_AUTH="${TARGET_USER_NAME}:${TARGET_AUTH_TOKEN}"

STORAGE_A_FILE="jpd_a_storageinfo.json"
STORAGE_B_FILE="jpd_b_storageinfo.json"

REPOCONFIG_A_FILE="jpd_a_repoconfig.json"
REPOCONFIG_B_FILE="jpd_b_repoconfig.json"

OUTPUT_LOCAL_CSV="local_repos_comparison.csv"
ONLY_IN_SOURCE_LOCAL="only_in_source_local.csv"
ONLY_IN_TARGET_LOCAL="only_in_target_local.csv"

OUTPUT_REMOTE_CSV="remote_repos_comparison.csv"
ONLY_IN_SOURCE_REMOTE="only_in_source_remote.csv"
ONLY_IN_TARGET_REMOTE="only_in_target_remote.csv"
OUTPUT_REMOTE_CONFIG_CSV="remote_repos_config_comparison.csv"

OUTPUT_VIRTUAL_CSV="virtual_repos_comparison.csv"
ONLY_IN_SOURCE_VIRTUAL="only_in_source_virtual.csv"
ONLY_IN_TARGET_VIRTUAL="only_in_target_virtual.csv"
OUTPUT_VIRTUAL_CONFIG_CSV="virtual_repos_config_comparison.csv"

#####Functions
usage() {
    echo "Usage: $0 <JPD_A_URL> <JPD_B_URL> <SOURCE_USER> <SOURCE_TOKEN> <TARGET_USER> <TARGET_TOKEN> [weboutput]"
    echo ""
    echo "Arguments:"
    echo "  JPD_A_URL      URL of the Source Artifactory (e.g., https://source.jfrog.io)"
    echo "  JPD_B_URL      URL of the Target Artifactory (e.g., https://target.jfrog.io)"
    echo "  SOURCE_USER    Admin username for Source JPD"
    echo "  SOURCE_TOKEN   Access Token for Source JPD"
    echo "  TARGET_USER    Admin username for Target JPD"
    echo "  TARGET_TOKEN   Access Token for Target JPD"
    echo "  weboutput      (Optional) Set to 'yes' to launch the HTML dashboard (default: no)"
    echo ""
    echo "Requirements:"
    echo "  - jq:       Required for JSON parsing."
    echo "  - python3:  Mandatory if using 'weboutput=yes' (to serve the dashboard)."
    echo ""
    echo "Example:"
    echo "  $0 \"https://src.io\" \"https://tgt.ioi\" \"admin\" \"cmVmdG...\" \"admin\" \"YWJj...\" \"yes\""
    exit 1
}

# Check if at least 6 arguments are provided
if [ "$#" -lt 6 ]; then
    usage
fi

GetSourceVersion()
{
JPDMainVersion=`curl -s -u "$SOURCE_AUTH" "${JPD_A_URL}/artifactory/api/system/version"  | jq -r '.version'`
JPDTargetVersion=`curl -s -u "$TARGET_AUTH" "${JPD_B_URL}/artifactory/api/system/version"  | jq -r '.version'`
echo "SourceJPDVersion,TargetJPDVersion" > JPDVersion.csv
echo "$JPDMainVersion,$JPDTargetVersion" >> JPDVersion.csv
JPDMainMajorVersion=`echo $JPDMainVersion  | cut -d "." -f1`

[ $JPDMainMajorVersion -eq 6 ] && jpd7=no
[ $JPDMainMajorVersion -eq 7 ] && jpd7=yes
}

LocalReposDetails()
{
echo "LocalRepoName,ExistsInTarget,SourceFilesCount,SourceUsedSpace,TargetFilesCount,TargetUsedSpace" > "$OUTPUT_LOCAL_CSV"
echo "LocalRepoName,FilesCount_Source,UsedSpace_Source" > "$ONLY_IN_SOURCE_LOCAL"
echo "LocalRepoName,FilesCount_Target,UsedSpace_Target" > "$ONLY_IN_TARGET_LOCAL"

echo "Processing Local Repos Details..."
jq -r '.repositoriesSummaryList[] | select(.repoType=="LOCAL") | .repoKey' "$STORAGE_A_FILE" | while read -r repo; do
    
    # Source Data
    filesA=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo) | .filesCount' "$STORAGE_A_FILE")
    sizeA=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo) | .usedSpace' "$STORAGE_A_FILE")
    
    # Target Check
    targetData=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo)' "$STORAGE_B_FILE")

    if [ -n "$targetData" ]; then
        exists="Yes"
        filesB=$(echo "$targetData" | jq -r '.filesCount')
        sizeB=$(echo "$targetData" | jq -r '.usedSpace')
    else
        exists="No"
        filesB="N/A"
        sizeB="N/A"
        # Log to "Only in Source" file
        echo "${repo},${filesA},${sizeA}" >> "$ONLY_IN_SOURCE_LOCAL"
    fi

    echo "${repo},${exists},${filesA},${sizeA},${filesB},${sizeB}" >> "$OUTPUT_LOCAL_CSV"
done

jq -r '.repositoriesSummaryList[] | select(.repoType=="LOCAL") | .repoKey' "$STORAGE_B_FILE" | while read -r repo; do
    
    # Check if this repo key is MISSING from Source JSON
    sourceCheck=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo) | .repoKey' "$STORAGE_A_FILE")
    
    if [ -z "$sourceCheck" ]; then
        filesB=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo) | .filesCount' "$STORAGE_B_FILE")
        sizeB=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo) | .usedSpace' "$STORAGE_B_FILE")
        
        echo "${repo},${filesB},${sizeB}" >> "$ONLY_IN_TARGET_LOCAL"
    fi
done

echo "------------------------------------------------"
echo "Report Generation Complete for Local Repositories!"
echo "1. Full Local Repos Comparison: $OUTPUT_LOCAL_CSV"
echo "2. Local Repos Missing in Target: $ONLY_IN_SOURCE_LOCAL"
echo "3. Local Repos Missing in Source: $ONLY_IN_TARGET_LOCAL"
}

RemoteReposDetails()
{

echo "RemoteRepoName,ExistsInTarget" > "$OUTPUT_REMOTE_CSV"
echo "RemoteRepoName" > "$ONLY_IN_SOURCE_REMOTE"
echo "RemoteRepoName" > "$ONLY_IN_TARGET_REMOTE"

echo "Processing Remote Repos Details"
jq -r '.repositoriesSummaryList[] | select(.repoType=="CACHE") | .repoKey' "$STORAGE_A_FILE" | while read -r repo; do


    # Target Check
    targetData=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo)' "$STORAGE_B_FILE")

    if [ -n "$targetData" ]; then
        exists="Yes"
    else
        exists="No"
        # Log to "Only in Source" file
        echo "${repo}" >> "$ONLY_IN_SOURCE_REMOTE"
    fi

    echo "${repo},${exists}" >> "$OUTPUT_REMOTE_CSV"
done

jq -r '.repositoriesSummaryList[] | select(.repoType=="CACHE") | .repoKey' "$STORAGE_B_FILE" | while read -r repo; do

    # Check if this repo key is MISSING from Source JSON
    sourceCheck=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo) | .repoKey' "$STORAGE_A_FILE")

    if [ -z "$sourceCheck" ]; then
        echo "${repo}" >> "$ONLY_IN_TARGET_REMOTE"
    fi
done

echo "------------------------------------------------"
echo "Report Generation Complete For Remote Repositories!"
echo "1. Full Remote Repos Comparison: $OUTPUT_REMOTE_CSV"
echo "2. Remote Repos Missing in Target: $ONLY_IN_SOURCE_REMOTE"
echo "3. Remote Repos Missing in Source: $ONLY_IN_TARGET_REMOTE"
}

VirtualReposDetails()
{
echo "VirtualRepoName,ExistsInTarget" > "$OUTPUT_VIRTUAL_CSV"
echo "VirtualRepoName" > "$ONLY_IN_SOURCE_VIRTUAL"
echo "VirtualRepoName" > "$ONLY_IN_TARGET_VIRTUAL"

echo "Processing Virtual Repos Details"
jq -r '.repositoriesSummaryList[] | select(.repoType=="VIRTUAL") | .repoKey' "$STORAGE_A_FILE" | while read -r repo; do


    # Target Check
    targetData=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo)' "$STORAGE_B_FILE")

    if [ -n "$targetData" ]; then
        exists="Yes"
    else
        exists="No"
        # Log to "Only in Source" file
        echo "${repo}" >> "$ONLY_IN_SOURCE_VIRTUAL"
    fi

    echo "${repo},${exists}" >> "$OUTPUT_VIRTUAL_CSV"
done 

jq -r '.repositoriesSummaryList[] | select(.repoType=="VIRTUAL") | .repoKey' "$STORAGE_B_FILE" | while read -r repo; do
    
    # Check if this repo key is MISSING from Source JSON
    sourceCheck=$(jq -r --arg repo "$repo" '.repositoriesSummaryList[] | select(.repoKey==$repo) | .repoKey' "$STORAGE_A_FILE")

    if [ -z "$sourceCheck" ]; then
        echo "${repo}" >> "$ONLY_IN_TARGET_VIRTUAL"
    fi
done
        
echo "------------------------------------------------"
echo "Report Generation Complete For Virtual Repositories!" 
echo "1. Full Virual Repository Comparison: $OUTPUT_VIRTUAL_CSV"
echo "2. Virtual Repos Missing in Target: $ONLY_IN_SOURCE_VIRTUAL"
echo "3. Virtual Repos Missing in Source: $ONLY_IN_TARGET_VIRTUAL"
}       


RemoteRepoConfigDetails2() {

    echo "SourceRepoName,SourceURL,SourcePasswordExists,TargetRepoName,TargetURL,TargetPasswordExists,ExistsInTarget" > "$OUTPUT_REMOTE_CONFIG_CSV"

    echo "Processing Remote Repo config comparision between JPDs"
    repoListA=$(curl -s -u "$SOURCE_USER_NAME:$SOURCE_AUTH_TOKEN" "$JPD_A_URL/artifactory/api/repositories?type=remote" | jq -r '.[].key')
    repoListB=$(curl -s -u "$TARGET_USER_NAME:$TARGET_AUTH_TOKEN" "$JPD_B_URL/artifactory/api/repositories?type=remote" | jq -r '.[].key')

    for repoA in $repoListA; do
        echo "Processing: $repoA"

        # 1. Fetch Source Repo Details to file
        curl -s -u "$SOURCE_USER_NAME:$SOURCE_AUTH_TOKEN" "$JPD_A_URL/artifactory/api/repositories/$repoA" > "$repoA.json"
        
        # 2. Extract values (tr -d '\n' handles the public key line breaks)
        urlA=$(cat "$repoA.json" | tr -d '\n' | jq -r '.url // "N/A"')
        passA=$(cat "$repoA.json" | tr -d '\n' | jq -r '.password // ""')
        [[ -z "$passA" || "$passA" == "null" ]] && SrcPasswordExists="No" || SrcPasswordExists="Yes"

        # 3. Check if repo exists in Target List
        if echo "$repoListB" | grep -Fwq "$repoA"; then
            exists="Yes"
            
            # Fetch and parse Target
            curl -s -u "$TARGET_USER_NAME:$TARGET_AUTH_TOKEN" "$JPD_B_URL/artifactory/api/repositories/$repoA" > "${repoA}_target.json"
            urlB=$(cat "${repoA}_target.json" | tr -d '\n' | jq -r '.url // "N/A"')
            passB=$(cat "${repoA}_target.json" | tr -d '\n' | jq -r '.password // ""')
            [[ -z "$passB" || "$passB" == "null" ]] && TgtPasswordExists="No" || TgtPasswordExists="Yes"
            
            rm "${repoA}_target.json"
        else
            exists="No"
            urlB="N/A"
            TgtPasswordExists="N/A"
        fi

        echo "$repoA,$urlA,$SrcPasswordExists,$repoA,$urlB,$TgtPasswordExists,$exists" >> "$OUTPUT_REMOTE_CONFIG_CSV"
        
        # Cleanup source file
        rm "$repoA.json"
    done
echo "Remote Repos Config comparison complete! Saved to: $OUTPUT_REMOTE_CONFIG_CSV"
}
RemoteRepoConfigDetails()
{       
        
echo "SourceRepoName,SourceURL,SourcePasswordExists,TargetRepoName,TargetURL,TargetPasswordExists,ExistsInTarget" > "$OUTPUT_REMOTE_CONFIG_CSV"
echo "Processing Remote Repo config comparision between JPDs"
jq -r '.REMOTE[] | "\(.key)|\(.url // "N/A")|\(.password // "")"' "$REPOCONFIG_A_FILE" | while IFS="|" read -r repoA urlA passA; do

    # Check Password for Source
    if [ -z "$passA" ] || [ "$passA" == "null" ]; then
        SrcPasswordExists="No"
    else
        SrcPasswordExists="Yes"
    fi

    # 2. Check if this repo exists anywhere in File B's REMOTE section and fetch its password
    targetData=$(jq -r --arg repo "$repoA" '.REMOTE[] | select(.key == $repo) | "\(.url // "N/A")|\(.password // "")"' "$REPOCONFIG_B_FILE")

    if [ -n "$targetData" ]; then
        exists="Yes"
        urlB=$(echo "$targetData" | cut -d'|' -f1)
        passB=$(echo "$targetData" | cut -d'|' -f2)

        # Check Password for Target
        if [ -z "$passB" ] || [ "$passB" == "null" ]; then
            TgtPasswordExists="No"
        else
            TgtPasswordExists="Yes"
        fi
    else
        exists="No"
        urlB="N/A"
        TgtPasswordExists="N/A"
    fi

    # Now you have: $SrcPasswordExists and $TgtPasswordExists
    # Update your echo command to include these new columns
    echo "$repoA,$urlA,$SrcPasswordExists,$repoA,$urlB,$TgtPasswordExists,$exists" >> "$OUTPUT_REMOTE_CONFIG_CSV"
done
echo "Remote Repos Config comparison complete! Saved to: $OUTPUT_REMOTE_CONFIG_CSV"
}

VirtualRepoConfigDetails()
{

# 1. Initialize CSV Header
# Column 8 (isDiff) will flag if the underlying repository lists don't match
HEADER="SourceRepoName,SourceRepositories,SourceDefaultDeploy,TargetRepoName,TargetRepositories,TargetDefaultDeploy,ExistsInTarget,DifferenceInRepos"
echo "$HEADER" > "$OUTPUT_VIRTUAL_CONFIG_CSV"

echo "Processing Virtual Repos config comparision between JPDs"

# 2. Extract specifically from the .VIRTUAL array
# We join the 'repositories' array using join(";") for easier CSV handling
jq -r '.VIRTUAL[] | "\(.key)|\(.repositories | join(";"))|\(.defaultDeploymentRepo // "N/A")"' "$REPOCONFIG_A_FILE" | while IFS="|" read -r repoA childrenA deployA; do

    # 3. Search for the same Virtual Repo in File B
    targetMatch=$(jq -r --arg repo "$repoA" '.VIRTUAL[] | select(.key == $repo) | "\(.key)|\(.repositories | join(";"))|\(.defaultDeploymentRepo // "N/A")"' "$REPOCONFIG_B_FILE")

    if [ -n "$targetMatch" ]; then
        exists="Yes"
        repoB=$(echo "$targetMatch" | cut -d'|' -f1)
        childrenB=$(echo "$targetMatch" | cut -d'|' -f2)
        deployB=$(echo "$targetMatch" | cut -d'|' -f3)

        # 4. Check for differences in the underlying repository list
        if [ "$childrenA" == "$childrenB" ]; then
            isDiff="No"
        else
            isDiff="Yes"
        fi
    else
        exists="No"
        repoB="N/A"
        childrenB="N/A"
        deployB="N/A"
        isDiff="N/A"
    fi

    # Append to CSV
    echo "${repoA},\"${childrenA}\",${deployA},${repoB},\"${childrenB}\",${deployB},${exists},${isDiff}" >> "$OUTPUT_VIRTUAL_CONFIG_CSV"
done

echo "------------------------------------------------"
echo "Virtual Repos Config comparison complete! Saved to: $OUTPUT_VIRTUAL_CONFIG_CSV"
}

VirtualRepoConfigDetails2() {
    # 1. Initialize CSV Header
    HEADER="SourceRepoName,SourceRepositories,SourceDefaultDeploy,TargetRepoName,TargetRepositories,TargetDefaultDeploy,ExistsInTarget,DifferenceInRepos"
    echo "$HEADER" > "$OUTPUT_VIRTUAL_CONFIG_CSV"

    echo "Processing Virtual Repos config comparision between JPDs"
    
    # Get Lists
    repoListA=$(curl -s -u "$SOURCE_USER_NAME:$SOURCE_AUTH_TOKEN" "$JPD_A_URL/artifactory/api/repositories?type=virtual" | jq -r '.[].key')
    repoListB=$(curl -s -u "$TARGET_USER_NAME:$TARGET_AUTH_TOKEN" "$JPD_B_URL/artifactory/api/repositories?type=virtual" | jq -r '.[].key')

    for repoA in $repoListA; do
        echo "Processing Virtual: $repoA"

        # 2. Fetch Source Virtual Details to file
        curl -s -u "$SOURCE_USER_NAME:$SOURCE_AUTH_TOKEN" "$JPD_A_URL/artifactory/api/repositories/$repoA" > "v_${repoA}_src.json"
        
        # Flatten and extract Source info
        # repositories are joined by ';' for CSV readability
        childrenA=$(cat "v_${repoA}_src.json" | tr -d '\n' | jq -r '.repositories | join(";") // "None"')
        deployA=$(cat "v_${repoA}_src.json" | tr -d '\n' | jq -r '.defaultDeploymentRepo // "N/A"')

        # 3. Check if repo exists in Target List
        if echo "$repoListB" | grep -Fwq "$repoA"; then
            exists="Yes"
            
            # Fetch and parse Target Virtual Details
            curl -s -u "$TARGET_USER_NAME:$TARGET_AUTH_TOKEN" "$JPD_B_URL/artifactory/api/repositories/$repoA" > "v_${repoA}_tgt.json"
            
            childrenB=$(cat "v_${repoA}_tgt.json" | tr -d '\n' | jq -r '.repositories | join(";") // "None"')
            deployB=$(cat "v_${repoA}_tgt.json" | tr -d '\n' | jq -r '.defaultDeploymentRepo // "N/A"')

            # 4. Compare underlying repo lists
            if [ "$childrenA" == "$childrenB" ]; then
                isDiff="No"
            else
                isDiff="Yes"
            fi
            
            rm "v_${repoA}_tgt.json"
        else
            exists="No"
            childrenB="N/A"
            deployB="N/A"
            isDiff="N/A"
        fi

        # 5. Write to CSV (using quotes around children to handle the ';' separator)
        echo "${repoA},\"${childrenA}\",${deployA},${repoA},\"${childrenB}\",${deployB},${exists},${isDiff}" >> "$OUTPUT_VIRTUAL_CONFIG_CSV"
        
        # Cleanup source file
        rm "v_${repoA}_src.json"
    done

    echo "------------------------------------------------"
    echo "Virtual Repos Config comparison complete! Saved to: $OUTPUT_VIRTUAL_CONFIG_CSV"
}

FormatRepoComparision()
{
FinalComparisionCSV="repo_comparision_consolidated.csv"

echo "" > $FinalComparisionCSV
echo "---------------------Local repository comparision Details------------------------" >> $FinalComparisionCSV
cat $OUTPUT_LOCAL_CSV >> $FinalComparisionCSV

echo "" >> $FinalComparisionCSV
echo "--------------------Remote repository comparision Details------------------------" >> $FinalComparisionCSV
cat $OUTPUT_REMOTE_CSV >> $FinalComparisionCSV

echo "" >> $FinalComparisionCSV
echo "--------------------Virtual repository comparision Details-----------------------" >> $FinalComparisionCSV
cat $OUTPUT_VIRTUAL_CSV >> $FinalComparisionCSV
}

FormatRepoConfigComparision()
{
FinalComparisionConfigCSV="repo_comparision_config_consolidated.csv"

echo "" > $FinalComparisionConfigCSV
echo "--------------------Remote repository config comparision Details------------------------" >> $FinalComparisionConfigCSV
cat $OUTPUT_REMOTE_CONFIG_CSV >> $FinalComparisionConfigCSV

echo "" >> $FinalComparisionConfigCSV
echo "--------------------Virtual repository config comparision Details-----------------------" >> $FinalComparisionConfigCSV
cat $OUTPUT_VIRTUAL_CONFIG_CSV >> $FinalComparisionConfigCSV
}

echo "Getting ready to Prepare comparision between the JPDs"
###Fetching storage info from both JPDs
curl -s -u "$SOURCE_AUTH" "${JPD_A_URL}/artifactory/api/storageinfo" -o "$STORAGE_A_FILE"
#curl -s -u "admin:Password1*" "https://mill.jfrog.info:12405/artifactory/api/storageinfo" -o "$STORAGE_A_FILE"
curl -s -u "$TARGET_AUTH" "${JPD_B_URL}/artifactory/api/storageinfo" -o "$STORAGE_B_FILE"

##--Fetch repo config json
curl -s -u "$SOURCE_AUTH" "${JPD_A_URL}/artifactory/api/repositories/configurations" -o "$REPOCONFIG_A_FILE"
curl -s -u "$TARGET_AUTH" "${JPD_B_URL}/artifactory/api/repositories/configurations" -o "$REPOCONFIG_B_FILE"

GetSourceVersion
LocalReposDetails
echo ""
RemoteReposDetails
echo ""
VirtualReposDetails
echo ""
if [ $jpd7 == "yes" ];then
	RemoteRepoConfigDetails
	echo ""
	VirtualRepoConfigDetails
	echo ""
else
	RemoteRepoConfigDetails2	
	echo ""
	VirtualRepoConfigDetails2
	echo ""
fi
FormatRepoComparision
echo ""
FormatRepoConfigComparision
echo ""
# --- 3. Web Server Automation ---
if [[ "$WEB_OUTPUT" == "yes" ]]; then
    echo "------------------------------------------------"
    echo "Starting Web Server on http://localhost:8000"
    echo "Dashboard: http://localhost:8000/CompareJPDsRepoConfig.html"
    echo "Press Ctrl+C to stop the server when finished."
    
    # Open the browser automatically based on OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open "http://localhost:8000/CompareJPDsRepoConfig.html" &>/dev/null &
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        open "http://localhost:8000/CompareJPDsRepoConfig.html" &>/dev/null &
    fi

    # Run the server (this will block the script until you hit Ctrl+C)
    python3 -m http.server 8000
else
    echo "------------------------------------------------"
    echo "Web output disabled. Reports generated in CSV format."
fi
