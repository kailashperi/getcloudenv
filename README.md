# getcloudenv 
Use a docker image for logging into IBM Dedicated and Local Cloud environments

Rather than setting proxies and finding API endpoints from Doctor, login to a docker contaniner with the endpoint, SSO user id and password obtained from the parent script. Advantages of using a containerized approach is that you can log into multiple environments at the same time avoiding Bluemix CLI dependency on the config folder. 

## Quick Start

```bash
docker pull kailashperi/getcloudenv
```
Once the image is pulled run the following script that can be downloaded from [IBM Cloud odds-and-ends repository](https://github.ibm.com/IBMCloudSupport/odds-and-ends/blob/master/ded-local-cli-access/getcloudenv.sh)
```getcloudenv.sh  -- Retreives Dedicated Local Environment Name, API URL and IBM Cloud Console URL

        Usage: getcloudenv.sh [ -f <filename> |  -k | -v ] -s env [-h] [-d] [-D] [-L]

        Options:

            Required Parameters:

                -f <filename> : filename from where to retrieve DOC_USER_ID and DOC_API_KEY values from (or)
                -k            : Reads DOC_API_KEY entry from keychain (or)
                -e            : Read DOC_USER_ID and DOC_API_KEY environment variables

                -s <env>      : Local / Dedicated environment to search for

            Optional Parameters:

                -d            : Print debug information
                -D            : Dedicated enviornment list
                -L            : Local environment list
                -h            : Print help
                
Usage: getcloudenv.sh -k -s <search string>
```

## Local Environment Setup 
For getcloudenv.sh script uses Doctor API, you need to provide (at the minimum) your Doctor ID and API key in a local file, keychain or environment variables based on the option you choose. Additionally, for logging into the environment you would need w3 password (for setting up the PROXY), SSO id and password.

* KeyChain option: 
  * When using keychain option to store the credentials, create a keychain entry <b>'DOC_API_KEY'</b> item in 'Password' section and ensure 'Name' is set to your DOC_USER_ID and Password is set to your DOC_API_KEY.
  
  * If you want to login to the environment automatically (without having to specify w3 password and SSO id / password 
    on the command line, you need two additional keychain entries <b>'IBM_w3'</b> and <b>'SSO_ID '</b> (both in Password 
    section of keychain) with 'Name' set to IBM_w3 / SSO id and 'Password' set to your w3 / SSO passwords respectively.
    
* File option: 
  * When using file option, ensure that the file has the following entries for logging into the environment 
    automatically. The minimum entries required are DOC_USER_ID and DOC_API_KEY (you will be prompted for w3 password, 
    SSO id / password if those entries are missing) for logging into the environment.<br><br>
    DOC_USER_ID="\<Doctor ID\>"<br>
    DOC_API_KEY="\<Doctor API Key\>"<br>
    W3_PASSWD="\<w3 Password\>"<br>
    SSO_ID="\<SSO id\>"<br>
    SSO_PASSWD="\<SSO Password\>"<br>
    
 * Environment Variable option: 
    * When using environment variable option, ensure that the following environment variables are exported for 
    logging into the environment automatically. The minimum entries required are DOC_USER_ID and DOC_API_KEY (you will be prompted for w3 password, SSO id / password if the other respective are missing) for logging into the environment.<br><br>
    DOC_USER_ID="\<Doctor ID\>"<br>
    DOC_API_KEY="\<Doctor API Key\>"<br>
    W3_PASSWD="\<w3 Password\>"<br>
    SSO_ID="\<SSO id\>"<br>
    SSO_PASSWD="\<SSO Password\>"<br>
