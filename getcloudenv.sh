#! /usr/local/Cellar/bash/4.4.19/bin/bash

FILENAME=""
KEYCHAIN=""
ENVVAR=""
SEARCHSTR=""
PROXY=proxy.opscenter.bluemix.net:1080
CURL_OPTIONS="curl --silent -k -X GET -d "
FLD_LST="\"[.account.account_name, .accessInfo.cf_api_url, .accessInfo.admin_ui_url] | @csv \""
DR_API_KEY=""
DR_USER_ID=""
DR_URL=""
DEBUG_IS_ON=no
W3_UID=""
W3_PWD=""
SSO_USER=""
SSO_PW=""
env_set_up_complete=0
list_dedicated=false
list_local=false

function debug() 
{
  if [ "${DEBUG_IS_ON}" = "yes" ]
  then
    echo "Debug: ${*}" >&2
  fi
}

function printUsage () 
{
    echo  "getcloudenv.sh  -- Retreives Dedicated Local Environment Name, API URL and IBM Cloud Console URL

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
                -h            : Print help "
         
}

function isVPN_Active ()
{
    #!-- Check whether user has connection via VPN since Doctor uses different endpoints for VPN and IBM network connections

    if [ !  -f /opt/cisco/anyconnect/bin/vpn ]
    then
            echo "Please specify the location of Cisco AnyConnect" 
            exit
    else    
            vpn_state=`/opt/cisco/anyconnect/bin/vpn state  | grep state | cut -d":" -f2 | uniq`
    fi

    if [ $vpn_state == "Connected" ]; then
        DR_URL="https://api-nat-oss.bluemix.net"
    else
        DR_URL="https://api-oss.bluemix.net"
    fi

    debug isVPN_Active:: "VPN: " $vpn_active "Doctor URL: " $DR_URL
}
    
function getVarsFromFile ()
{   
    #!-- Get user id and api key from file

    if [ -f $FILENAME ]; then
       source ${FILENAME}
        DR_USER_ID="$DOC_USER_ID"
        DR_API_KEY="$DOC_API_KEY"
        W3_UID="$W3_ID"
        W3_PWD="$W3_PASSWD"
        SSO_USER="$SSO_ID"
        SSO_PW="$SSO_PASSWD"
    fi

    debug getVarsFromFile:: "User: " $DR_USER_ID "ApiKey: " $DR_API_KEY "w3 ID: " $W3_UID "w3 Passwd: " $W3_PWD "SSO Id: " $SSO_ID "SSO Passwd: " $SSO_PW
}

function getVarsFromEnv ()
{
    #!-- Get user id and api key from environment 
    
    if [ -z ${DOC_USER_ID+x} ]; then
        echo "DOC_USER_ID environment variable is not set"
        exit
    else
        DR_USER_ID=$DOC_USER_ID
    fi

    if [ -z ${DOC_API_KEY} ]; then
        echo "DOC_API_KEY environment variable is not set"
        exit
    else
        DR_API_KEY=$DOC_API_KEY
    fi

    if [ ! -z ${W3_ID+x} ]; then
       W3_UID=$W3_ID
    fi

    if [ ! -z ${W3_PASSWD+x} ]; then
       W3_PWD=$W3_PASSWD
    fi

    if [ ! -z ${SSO_ID+x} ]; then
        SSO_USER=$SSO_ID
    fi

    if [ ! -z ${SSO_PASSWD+x} ]; then
        SSO_PW=$SSO_PASSWD
    fi

    debug getVarsFromEnv:: "User: " $DR_USER_ID "ApiKey: " $DR_API_KEY "w3 ID: " $W3_UID "w3 Passwd: " $W3_PWD "SSO Id: " $SSO_ID "SSO Passwd: " $SSO_PW
}

function getVarsFromKeyChain ()
{
    #!-- Get user id and api key from keychain
    
    DR_API_KEY=`/usr/bin/security  2>&1 > /dev/null find-generic-password -gs  DOC_API_KEY  | ruby -e 'print $1 if STDIN.gets =~ /^password: "(.*)"$/'`
    DR_USER_ID=`security find-generic-password -gs 'DOC_API_KEY' 2>&1 | grep acct | sed -e 's/.*"\(.*\)"/\1/'`

    W3_PWD=`/usr/bin/security  2>&1 > /dev/null find-generic-password -gs  IBM_w3  | ruby -e 'print $1 if STDIN.gets =~ /^password: "(.*)"$/'`
    W3_UID=`security find-generic-password -gs 'IBM_w3' 2>&1 | grep acct | sed -e 's/.*"\(.*\)"/\1/'`

    SSO_PW=`/usr/bin/security  2>&1 > /dev/null find-generic-password -gs  SSO_ID  | ruby -e 'print $1 if STDIN.gets =~ /^password: "(.*)"$/'`
    SSO_USER=`security find-generic-password -gs 'SSO_ID' 2>&1 | grep acct | sed -e 's/.*"\(.*\)"/\1/'`
    

    debug getVarsFromKeyChain:: "User: " $DR_USER_ID "ApiKey: " $DR_API_KEY "w3 ID: " $W3_UID "w3 Passwd: " $W3_PWD "SSO Id: " $SSO_USER "SSO Passwd: " $SSO_PW
}

function call_the_doctor ()
{
    accounts_list_url="$DR_URL/dlt/accounts"
    account_details_url="$DR_URL/dlt/account/"
    
    if [[ "$list_dedicated" == "true" ]]; then
        env_type="\"dedicated\""
    elif [[ "$list_local" == "true" ]]; then
            env_type="\"local\""
    fi

    debug call_the_doctor:: "Env Type: " $env_type

    if [ ! -z "$env_type" ]; then
        debug call_the_doctor:: $accounts_list_url
        #!echo "`$CURL_OPTIONS  \"user_name=$DR_USER_ID&api_key=$DR_API_KEY&\" $accounts_list_url | jq -r '.accounts[] | select (.offering_type=='$env_type') | [.account_id, .account_name] | @tsv'`"
        var1="`$CURL_OPTIONS  \"user_name=$DR_USER_ID&api_key=$DR_API_KEY&\" $accounts_list_url | jq -r '.accounts[] | select (.offering_type=='$env_type') | [.account_id, .account_name] | @csv'`"
        num_recs=`echo "$var1" | wc -l`
        debug "Ded Env: " $var1
    else
        debug "Command: " $CURL_OPTIONS \"user_name=$DR_USER_ID\&api_key=$DR_API_KEY\&\" $accounts_list_url \| jq -r \'.accounts[] \| [.account_id,  .account_name] \| @csv \' \|  grep -i $SEARCHSTR\"
        var1="`$CURL_OPTIONS \"user_name=$DR_USER_ID&api_key=$DR_API_KEY&\" $accounts_list_url | jq -r '.accounts[] | [.account_id,  .account_name] | @csv ' |  grep -i $SEARCHSTR`"
        num_recs=`echo "$var1" | wc -l`

        debug call_the_doctor:: "Environment: " $var1
        env_set_up_complete=`echo $var1 | grep -o "," | wc -w`
        debug call_the_doctor:: "Number of Fields: " $env_set_up_complete
    fi

    
    IFS=$'\n'

    if [ "${#var1}" -eq "0" ]; then
        echo "No Environments Found"
        exit
    else
        num_recs=`echo "$var1" | wc -l`
        debug call_the_doctor:: $var1 "Found: " $num_recs "environments" "Setup Complete: " $env_set_up_complete
        echo  "Found: " $num_recs "environments"
        echo ""
        if [ "$env_type" != "local" ] && [ "$env_type" != "dedicated" ] && [ "$env_set_up_complete" -eq 1 ]; then
            debug  "EnvType: " $env_type 
            echo "API Endpoint is empty. Environment setup might not be complete. "
            exit
        fi
    fi

    counter=1

    if [ $num_recs -gt 1 ]; then
        for item in $var1
        do
            env=`echo $item | cut -f2 -d"," | sed 's/"//g'`
            envnum[counter]=`echo $item | cut -f1 -d"," | sed 's/"//g'`
            echo $counter. $env 
            ((counter++))
        done

        echo ""
        correctSelection="false"
        until [ correctSelection == "true" ]; do
            read -p  'Please make a selection or  0 for all environments :  ' selection
            
            if [[ $selection -lt 1 || $selection -le $num_recs ]]; then
                    correctSelection="true"
                    break
            else
                echo "Invalid Selection"
                tput cuu1       
            fi
        done
    fi

    echo ""

    yellow=$(tput setaf 3)
    blue=$(tput setaf 4)
    cyan=$(tput setaf 6)
    normal=$(tput sgr0)

    if [ "$selection" != "0" ]; then
        get_env="$CURL_OPTIONS \"user_name=$DR_USER_ID&api_key=$DR_API_KEY\" $account_details_url${envnum[selection]} | jq -r  $FLD_LST"
        debug call_the_doctor:: $get_env
        eval result=\$\($get_env\)

        IFS=',' read -r -a array <<< "$result"
                
        printf "%-15s %-40s %-40s\n" "Environment" "API End Point" "Console URL"
        printf "%-15s %-40s %-40s\n" "-----------" "-------------" "-----------"
        
        array[0]=$(echo ${array[0]} | sed 's/"//g')
        array[1]=$(echo ${array[1]} | sed 's/"//g')
        array[2]=$(echo ${array[2]} | sed 's/"//g')
        
        if [ ${array[2]} ];
            then
                array[2]="${array[2]}/landing?realmid=ibm"
                env_set_up_complete=1
        else
                debug call_the_doctor:: "Env Setup Completed: " $env_set_up_complete
                env_set_up_complete=0
        fi

        printf "%-20s %-45s %-30s\n" "${blue}${array[0]}" "${cyan}${array[1]}" "${yellow}${array[2]}${normal}"

    else
        counter=1

        printf "%-15s %-40s %-40s\n" "Environment" "API End Point" "Console URL"
        printf "%-15s %-40s %-40s\n" "-----------" "-------------" "-----------"

        for (( c=1; c <= $num_recs; c++ )) 
            do
                get_env="$CURL_OPTIONS \"user_name=$DR_USER_ID&api_key=$DR_API_KEY\" $account_details_url${envnum[c]} | jq -r  $FLD_LST"
                eval result=\$\($get_env\)
                debug call_the_doctor:: "Env / Result: " $get_env $result

                IFS=',' read -r -a array <<< "$result"
                array[0]=$(echo ${array[0]} | sed 's/"//g')
                array[1]=$(echo ${array[1]} | sed 's/"//g')
                array[2]=$(echo ${array[2]} | sed 's/"//g')


                if [ ${array[2]} ];
                    then
                    array[2]="${array[2]}landing?realmid=ibm"
                fi

                printf "%-20s %-45s %-30s\n" "${blue}${array[0]}" "${cyan}${array[1]}" "${yellow}${array[2]}${normal}"
            done
            exit
    fi

    echo "" 

    if [ $env_set_up_complete -ne 0 ]; then
        while true; do
            read -p "Do you wish to login to the Environment? " yn

            case $yn in

                [Yy]* ) 
                        if [ "$W3_UID" != "" ] && [ "$W3_PWD" != "" ] && [ "$SSO_USER" != "" ] && [ "$SSO_PW" != "" ]; then
                            export https_proxy="$W3_UID:$W3_PWD@$PROXY"
                            docker run -ti -e HTTPS_PROXY=$https_proxy -e W3_UID=$W3_UID -e W3_PWD=$W3_PWD -e END_POINT="${array[1]}" -e SSO_USER=$SSO_USER -e SSO_PW=$SSO_PW kailashperi/getcloudenv 
                            #`which bx` login -a  ${array[1]} -u $SSO_USER -p $SSO_PW

                        else
                            echo ""
                            read -p "Enter w3 ID : " uname; 
                            echo "Enter w3 Password : "
                            read -s pwd;
                            read -p "Enter SSO ID : " sso_id;
                            echo "Enter SSO Password :  " 
                            read -s sso_pwd;
                            export https_proxy="http://$uname:$pwd@$PROXY"
                            `which bx` login -a ${array[1]} -u $sso_id -p $sso_pwd
                        fi
                        break;;

                [Nn]* ) exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

#!-------------

if [ $# -lt 1 ]; then
    printUsage
    exit
fi

#!-- Parse command line args

while getopts "DLhkef:s:d" opt; do
    case "${opt}" in
        D) list_dedicated=true
            ;;
        L) list_local=true
            ;;
        f) FILENAME=${OPTARG}
            ;;
        k) KEYCHAIN=true
            ;;
        e) ENVVAR=true
            ;;
        s) SEARCHSTR=${OPTARG}
            ;;
        d) DEBUG_IS_ON=yes
            ;;
        h|*)
            printUsage;
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

debug "Options: " "File [" $FILENAME "] Keychain: [" $KEYCHAIN "] Envvar: [" $ENVVAR "] Search For: [" $SEARCHSTR "]"
debug "Debug : [" $DEBUG_IS_ON "] Local: [" $list_local "] Dedicated: [" $list_dedicated "]"

if [[ "$list_local" != false || "$list_dedicated" != false ]]; 
    then
        if [[ ! -z "$FILENAME" ]];
        then
            getVarsFromFile
        elif [[ ! -z "$KEYCHAIN" ]];
        then
            getVarsFromKeyChain
        elif [[ ! -z "$ENVVAR" ]];
        then
            getVarsFromEnv
        else
            echo "Please specify -f | -k | -v option along with -D or -L"
            printUsage
            exit 1
        fi
        isVPN_Active
        call_the_doctor $DR_URL $DR_USER_ID $DR_API_KEY

fi

if [[ "$FILENAME" != "" ]] || [[ "$KEYCHAIN" == "true" || "$ENVVAR" == "true" ]];
    then
    if [ "$SEARCHSTR" == "" ];
    then
        echo "Search string can not be blank"
        printUsage
        exit 1
    fi
else
    printUsage
    exit 1
fi

if [[ ! -z "$FILENAME" ]] &&  [[ ! -z "$SEARCHSTR" ]];
    then 
       if [ ! -f $FILENAME ];
       then
            echo "File [ " $FILENAME " ] containing environment variables does not exist"
            printUsage 
            exit
        fi

        if [[ -z "$SEARCHSTR" ]];
            then
            echo "Search string is a required parameter along with filename"
            printUsage
            exit
       fi
elif [[ "$KEYCHAIN" == "true" || "$ENVVAR" == "true" ]] && [ -z "$SEARCHSTR" ];
    then
        echo "Search string is a required parameter with keychain or environment variable"
        echo ""
        printUsage
fi

if  ( [[ -n $FILENAME ]] && [[ -n $KEYCHAIN ]] ) ||
        ( [[ -n $FILENAME ]] && [[ -n $ENVVAR ]] ) ||
        ( [[ -n $KEYCHAIN ]] && [[ -n $ENVVAR  ]] )
    then
        echo "Options File [-f], Keychain [-k] and Enironment [ -v ] are mutually exclusive"
        echo ""
        printUsage
        exit 1
fi

if [[ "$KEYCHAIN" == "true" ]] 
    then
        getVarsFromKeyChain
elif [[ "$ENVVAR"  == "true" ]]
    then
        getVarsFromEnv
else 
        getVarsFromFile
fi

#!-- Check whether VPN is active (Doctor API uses different URLs for VPN and within IBM network)
isVPN_Active

#!-- Call Doctor
call_the_doctor $DR_URL $DR_USER_ID $DR_API_KEY
