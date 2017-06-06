#!/bin/bash
set -e

source /init.sh

printstep "Ajout du tag sur l'image docker latest courante d'Artifactory"
printstep "Vérification des paramètres d'entrée"
init_env
int_gitlab_api_env

LAST_COMMIT_ID=$(git log --format="%H" -n 1)

PROJECT_ID=`curl --silent --noproxy '*' --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects?search=$PROJECT_NAME" | jq .[0].id`
VERSION_ON_LAST_COMMIT=$(curl --silent --noproxy '*' --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$PROJECT_ID/repository/tags" | jq --arg commit_id "$LAST_COMMIT_ID" '.[] | select(.commit.id == "\($commit_id)")' | jq .name | tr -d '"')

if [[ -n $VERSION_ON_LAST_COMMIT ]]; then
    IMAGE=$ARTIFACTORY_DOCKER_REGISTRY/$PROJECT_NAMESPACE/$PROJECT_NAME
    docker login -u $ARTIFACTORY_CI_USER -p $ARTIFACTORY_CI_PASSWORD $ARTIFACTORY_DOCKER_REGISTRY
    docker pull $IMAGE
    docker tag $IMAGE $IMAGE:$VERSION_ON_LAST_COMMIT
    docker push $IMAGE:$VERSION_ON_LAST_COMMIT
    docker rmi $IMAGE:$VERSION_ON_LAST_COMMIT
else
    printerror "Aucun tag trouvé sur le dernier commit $LAST_COMMIT_ID"
fi
