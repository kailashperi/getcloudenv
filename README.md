# getcloudenv 
Use a docker image for logging into IBM Dedicated and Local Cloud environments

Rather than setting proxies and finding API endpoints from Doctor, login to a docker contaniner with the endpoint, SSO user id and password obtained from the parent script. Advantages of using a containerized approach is that you can log into multiple environments at the same time avoiding Bluemix CLI dependency on the config folder. 

## Quick Start

```bash
docker pull kailashperi/getcloudenv
```
Once the image is pulled run getcloudenv.sh from IBM Cloud DSET odds-and-ends repository
