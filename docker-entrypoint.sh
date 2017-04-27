#!/bin/bash
set -e

printstep() {
    # 36 is blue
    echo -e "\033[36m\n== ${1} \033[37m \n"
}
printmainstep() {
   # 35 is purple
   echo -e "\033[35m\n== ${1} \033[37m \n"
}
printwarn () {
    # 33 is yellow
    echo -e "\033[33m==== ATTENTION : ${1} \033[37m"
}
printerror () {
    # 31 is red
    echo -e "\033[31m==== ERREUR : ${1} \033[37m"
}
printinfo () {
    # 32 is green
    echo -e "\033[32m==== INFO : ${1} \033[37m"
}

printstep "Ajout du tag sur l'image docker latest courante d'Artifactory"
REPO_URL=$(git config --get remote.origin.url | sed 's/\.git//g' | sed 's/\/\/.*:.*@/\/\//g')
GITLAB_URL=`echo $REPO_URL | grep -o 'https\?://[^/]\+/'`
GITLAB_API_URL="$GITLAB_URL/api/v4"
LAST_COMMIT_ID=$(git log --format="%H" -n 1)

PROJECT_ID=`curl --silent --noproxy '*' --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects?search=$CI_PROJECT_NAME" | jq .[0].id`
echo $GITLAB_TOKEN
echo $GITLAB_API_URL
echo $PROJECT_ID
VERSION_ON_LAST_COMMIT=$(curl --silent --noproxy '*' --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$PROJECT_ID/repository/tags" | jq --arg commit_id "$LAST_COMMIT_ID" '.[] | select(.commit.id == "\($commit_id)")' | jq .name | tr -d '"')

echo "LAST_COMMIT_ID         : $LAST_COMMIT_ID"
echo "VERSION_ON_LAST_COMMIT : $VERSION_ON_LAST_COMMIT"

if [[ -z $VERSION_ON_LAST_COMMIT ]]; then
    IMAGE=$ARTIFACTORY_DOCKER_REGISTRY/$CI_PROJECT_NAMESPACE/$CI_PROJECT_NAME
    docker pull $IMAGE
    echo "TAGGED_IMAGE : $IMAGE $IMAGE:$VERSION_ON_LAST_COMMIT"
    docker tag $IMAGE $IMAGE:$VERSION_ON_LAST_COMMIT
fi
