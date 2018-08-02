# G-DOCK

You need the Dockerfile, docker-compose.yml, apache.conf, and g-dock.sh in the root. Your website files should be in /public.

You'll need to set up the Google Cloud and all that stuff. Just read the Dockerfile and g-dock.sh if you wish.

G-dock should be cloned into a directory alongside a directory named 'root' containing all of your site/app files.

To run:

```
./gcloud-autodeploy.sh GCLOUD_PROJECTID PROJECT_NAME GCP_SERVICEACCOUNT FQDN GDNS_ZONENAME
```

e.g:

```
./gcloud-autodeploy.sh personal-201216 billing-core 29112554465-compute@developer.gserviceaccount.com dev.italkincode.com i-talk-in-code
```

This example should result in the Docker image being deployed to GCP, accessible via the FQDN (domain name): http://billing-core.dev.italkincode.com.

_I will write a proper README when I can be bothered_
