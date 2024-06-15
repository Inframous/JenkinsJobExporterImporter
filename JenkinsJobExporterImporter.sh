#!/bin/bash

# Check and set environment variables interactively if missing
: ${JENKINS_URL:=$(dialog --inputbox "Enter the full Jenkins URL:" 10 60 3>&1 1>&2 2>&3)}
: ${JENKINS_USER:=$(dialog --inputbox "Enter Jenkins Username:" 10 60 3>&1 1>&2 2>&3)}
: ${JENKINS_TOKEN:=$(dialog --passwordbox "Enter Jenkins Password/Token:" 10 60 3>&1 1>&2 2>&3 && echo "")}

# Export the variables so they can be used by functions
export JENKINS_URL
export JENKINS_USER
export JENKINS_TOKEN

# Constants
JOBS_DIR="/var/jobs"
JENKINS_CLI_JAR="jenkins-cli.jar"

# Function to download Jenkins CLI if not already downloaded
download_jenkins_cli() {
    if [ ! -f "$JENKINS_CLI_JAR" ]; then
        dialog --infobox "Downloading Jenkins CLI..." 5 50
        curl -sS "$JENKINS_URL/jnlpJars/jenkins-cli.jar" -o "$JENKINS_CLI_JAR"
    fi
}

# Function to get the list of Jenkins jobs
get_jenkins_jobs() {
    java -jar "$JENKINS_CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_TOKEN" list-jobs
}

# Function to export a Jenkins job to an XML file
export_job_to_xml() {
    local job_name="$1"
    local xml_file="${JOBS_DIR}/${job_name// /_}.xml"  # Replace spaces with underscores
    dialog --infobox "Exporting job '$job_name' to '$xml_file'..." 5 50
    java -jar "$JENKINS_CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_TOKEN" get-job "$job_name" > "$xml_file"
}

# Function to import a Jenkins job from an XML file
import_job_from_xml() {
    local xml_file="$1"
    local job_name=$(basename "$xml_file" .xml)
    job_name="${job_name//_/ }"  # Replace underscores with spaces
    dialog --infobox "Importing job $job_name from '$xml_file'..." 5 50
    java -jar "$JENKINS_CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_TOKEN" create-job "$job_name" < "$xml_file"
}

# Main script execution starts here

# Download Jenkins CLI if necessary
download_jenkins_cli

# Menu to select operation
operation=$(dialog --menu "Select operation" 15 60 2 \
    1 "Export Jobs" \
    2 "Import Jobs" \
    3>&1 1>&2 2>&3)

# Handle the operation selection
if [ "$operation" == "1" ]; then
    # Create jobs directory if it doesn't exist
    mkdir -p "$JOBS_DIR"

    # Fetch list of Jenkins jobs
    dialog --infobox "Fetching list of Jenkins jobs..." 5 50
    JOBS=$(get_jenkins_jobs)

    # Convert jobs into an array for dialog
    IFS=$'\n' read -rd '' -a job_array <<< "$JOBS"

    # Prepare dialog options
    dialog_options=("0" "Select All" "off")
    for i in "${!job_array[@]}"; do
        dialog_options+=("$((i+1))" "${job_array[$i]}" "off")
    done

    # Dialog to choose jobs for export
    tempfile=$(mktemp)
    dialog --checklist "Choose jobs to export:" 20 60 ${#dialog_options[@]} "${dialog_options[@]}" 2> "$tempfile"
    selections=$(< "$tempfile")
    rm "$tempfile"

    # Process export selections
    if [[ $selections == *0* ]]; then
        dialog --infobox "Exporting all jobs..." 5 50
        for job in "${job_array[@]}"; do
            export_job_to_xml "$job"
        done
    else
        dialog --infobox "Exporting selected jobs..." 5 50
        for selection in $selections; do
            case_index=$((selection-1))
            if [[ $case_index -ge 0 && $case_index -lt ${#job_array[@]} ]]; then
                export_job_to_xml "${job_array[$case_index]}"
            else
                dialog --msgbox "Invalid selection: $selection" 10 60
            fi
        done
    fi

elif [ "$operation" == "2" ]; then
    # Select folder for job import
    : ${IMPORT_FOLDER:=$(dialog --inputbox "Enter import folder path (within the container) or leave default:" 10 60 "$JOBS_DIR" 3>&1 1>&2 2>&3)}
    export IMPORT_FOLDER

    # Find all XML files in import folder
    xml_files=("$IMPORT_FOLDER"/*.xml)

    # Prepare dialog options
    dialog_options=("0" "Select All" "off")
    for i in "${!xml_files[@]}"; do
        file_name=$(basename "${xml_files[$i]}")
        dialog_options+=("$((i+1))" "$file_name" "off")
    done

    # Dialog to choose jobs for import
    tempfile=$(mktemp)
    dialog --checklist "Choose jobs to import:" 20 60 ${#dialog_options[@]} "${dialog_options[@]}" 2> "$tempfile"
    selections=$(< "$tempfile")
    rm "$tempfile"

    # Process import selections
    if [[ $selections == *0* ]]; then
        dialog --infobox "Importing all jobs..." 5 50
        for xml_file in "${xml_files[@]}"; do
            import_job_from_xml "$xml_file"
        done
    else
        dialog --infobox "Importing selected jobs..." 5 50
        for selection in $selections; do
            case_index=$((selection-1))
            if [[ $case_index -ge 0 && $case_index -lt ${#xml_files[@]} ]]; then
                import_job_from_xml "${xml_files[$case_index]}"
            else
                dialog --msgbox "Invalid selection: $selection" 10 60
            fi
        done
    fi

else
    dialog --msgbox "Invalid operation selected." 10 60
fi
