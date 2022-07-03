access_token=`curl -X PUT "http://169.254.169.254/instance_identity/v1/token?version=2022-06-30"\
  -H "Metadata-Flavor: ibm"\
  -H "Accept: application/json"\
  -d '{ 
        "expires_in": 3600 
      }' | jq -r '(.access_token)'`
curl -X GET "http://169.254.169.254/metadata/v1/instance?version=2022-06-30"\
   -H "Accept: application/json"\
   -H "Authorization: Bearer $access_token"\
   | jq -r