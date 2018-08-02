#/bin/sh

#
# Command-line utility which builds a Docker image of the local container (in the working directory), deploys it to Google Compute, attaches it to the Google DNS zonefile, and returns a working web-based subdomain to access whatever the container would serve.
#

#
# THIS REQUIRES INSTALLATION OF THE gcloud sdk, AUTHORISATION WITH THE SDK ON THE MACHINE YOU'RE RUNNING ON, AND OBVIOUSLY A GOOGLE CLOUD ACCOUNT WITH THE RELEVANT SERVICES ENABLED (Container Registry, Virtual Compute, Cloud DNS)
#

#
# To run:
#
# ./g-dock.sh GCLOUD_PROJECTID PROJECT_NAME GCP_SERVICEACCOUNT FQDN GDNS_ZONENAME
#
# e.g:
#
# ./g-dock.sh personal-201216 billing-core 29112554465-compute@developer.gserviceaccount.com dev.italkincode.com i-talk-in-code
#
# This example should result in the Docker image being deployed to GCP, accessible via the FQDN: http://billing-core.dev.italkincode.com.
#
#

## TODO: Move these variables to a .env or equivalent file


GCLOUD_PROJECTID=$1
PROJECT_NAME=$2
GCP_SERVICEACCOUNT=$3
FQDN=$4
GDNS_ZONENAME=$5

## LOCAL
#docker-compose up --build

# Delete the last image that might be in place
docker rm -f gcr.io/$GCLOUD_PROJECTID/$PROJECT_NAME:0.0.1

# Docker build the image
docker build -t gcr.io/$GCLOUD_PROJECTID/$PROJECT_NAME:0.0.1 .


## REMOTE

# Delete existing container image first
gcloud beta container images delete gcr.io/$GCLOUD_PROJECTID/$PROJECT_NAME --force-delete-tags

# Create the new container with this Docker image
gcloud docker -- push gcr.io/$GCLOUD_PROJECTID/$PROJECT_NAME:0.0.1

# Launch a new VM based on the newly pushed container
gcloud beta compute instances create-with-container $PROJECT_NAME --container-image gcr.io/$GCLOUD_PROJECTID/$PROJECT_NAME:0.0.1 --machine-type g1-small --tags http-server --service-account=$GCP_SERVICEACCOUNT --format=json

# Make the IP of this new VM available in the script
export NEWVM_IP=$(gcloud beta compute instances describe $PROJECT_NAME --format=json | grep natIP | tr -d '""' | tr -d 'natIP' | tr -d ': ' | tr -d ',' | tr -d ' ')

# Add an A-record to the dev domain zonefile
NEW_ARECORD="$PROJECT_NAME.$FQDN."

## TODO: Remove any previous A records for this new sub-domain
gcloud dns record-sets transaction start -z=$GDNS_ZONENAME
gcloud dns record-sets transaction remove --name=$NEW_ARECORD --type=A -z=$GDNS_ZONENAME --ttl=300
gcloud dns record-sets transaction add -z=$GDNS_ZONENAME --name=$NEW_ARECORD --type=A --ttl=300 $NEWVM_IP
gcloud dns record-sets transaction execute -z=$GDNS_ZONENAME

echo $NEW_ARECORD
