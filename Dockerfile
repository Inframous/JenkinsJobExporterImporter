# Use an official lightweight Alpine image
FROM alpine:latest

# Install necessary packages
RUN apk update && apk add --no-cache \
    openjdk11-jre \
    curl \
    jq \
    dialog \
    bash

# Create a directory for the script and jobs
WORKDIR /app

# Add Environment Variables

ENV JENKINS_URL=
ENV JENKINS_USER=
ENV JENKINS_TOKEN=

ENV IMPORT_FOLDER=

# Copy the script into the container
COPY ./JenkinsJobExporterImporter.sh /app/JenkinsJobExporterImporter.sh

# Make the script executable
RUN chmod +x /app/JenkinsJobExporterImporter.sh

# Set the default command to run the script
CMD ["./JenkinsJobExporterImporter.sh"]
