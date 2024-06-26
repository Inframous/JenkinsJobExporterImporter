# Docker Image: Jenkins Job Exporter/Importer

This Docker image facilitates exporting and importing Jenkins jobs using a script (`JenkinsJobExporterImporter.sh`) inside the container.

## Usage

### Environment Variables

- `JENKINS_URL`: The full URL of your Jenkins instance.
- `JENKINS_USER`: Username for authentication with Jenkins.
- `JENKINS_TOKEN`: Token or password for authentication with Jenkins.
- `IMPORT_FOLDER`: (Optional) Folder path inside the container where XML job configuration files are stored for import.

### Running the Container

To run the Docker container with this image, use the following commands to clone the repo, build the image and run the container:

```bash
$ git clone https://github.com/Inframous/JenkinsJobExporterImporter.git
$ cd JenkinsJobExporterImporter
$ docker build -t jenkins-job-exporter-importer .
$ docker run --rm -it \
     -v ./my_job:/var/jobs
     -e JENKINS_URL=<your_jenkins_url> \
     -e JENKINS_USER=<your_jenkins_user> \
     -e JENKINS_TOKEN=<your_jenkins_token> \
     -e IMPORT_FOLDER=<optional_import_folder_path> \
     jenkins-job-exporter-importer:latest
```
### Notes: 
- The exported jobs will be downloaded to ```/var/jobs``` <b>inside</b> the container, so make sure to mount a local folder to that location.
- This might not work if your Jenkins Server is behind a Reversed Proxy, if you encounter problems try pointing to the server directly.
