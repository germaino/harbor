#!/bin/bash

export HOST="localhost"


echo "Get token"
export TOKEN=\
"$(curl \
--silent \
--key ./certs/users/germaino.key \
--cert ./certs/users/germaino.crt \
-H "Content-Type: application/json" \
"https://$HOST/service/token?service=harbor-registry&scope=repository:test/hello-world:pull,push" \
| jq -r '.token' \
)"

echo "Push image"

generate_jSON_STR()
{
  cat <<EOF
{
  "identitytoken": "$TOKEN"
}
EOF
}
REGISTRY_AUTH=$(echo $(generate_jSON_STR) | base64)
REGISTRY_AUTH_NO_SPACE=$(echo ${REGISTRY_AUTH} | tr -d ' ')


curl -v -X POST -H X-Registry-Auth:${REGISTRY_AUTH_NO_SPACE} --unix-socket /var/run/docker.sock http://localhost/images/$HOST/test/hello-world/push
#curl -v -X POST -H X-Registry-Auth:${REGISTRY_AUTH_NO_SPACE} --unix-socket /var/run/docker.sock http://localhost/images/create?fromImage=$HOST/test/hello-world
#curl --silent -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" --key ./certs/users/germaino.key --cert ./certs/users/germaino.crt https://$HOST/v2/test/images/json
curl --silent -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" --key ./certs/users/germaino.key --cert ./certs/users/germaino.crt https://$HOST/v2/test/hello-world/manifests/latest | jq -r '.fsLayers[].blobSum'

