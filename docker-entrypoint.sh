#!/bin/bash
set -e

source /init.sh

printmainstep "Ajout du tag sur l'image docker latest courante d'Artifactory"
printstep "Vérification des paramètres d'entrée"
init_env
int_gitlab_api_env

LAST_COMMIT_ID=$(git log --format="%H" -n 1)

IMAGE=$ARTIFACTORY_DOCKER_REGISTRY/$PROJECT_NAMESPACE/$PROJECT_NAME
PROJECT_ID=`myCurl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects?search=$PROJECT_NAME" | jq --arg project_namespace "$PROJECT_NAMESPACE" '.[] | select(.namespace.name == "\($project_namespace)") | .id'`
VERSION_ON_LAST_COMMIT=$(myCurl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$PROJECT_ID/repository/tags" | jq -r --arg commit_id "$LAST_COMMIT_ID" '.[] | select(.commit.id == "\($commit_id)") | .name')

if [[ -n $VERSION_ON_LAST_COMMIT ]]; then
    ARTIFACTORY_IMAGE_ID=`myCurl -u $ARTIFACTORY_USER:$ARTIFACTORY_PASSWORD "$ARTIFACTORY_URL/artifactory/docker/$PROJECT_NAMESPACE/$PROJECT_NAME/$VERSION_ON_LAST_COMMIT/manifest.json" | jq -r .config.digest`
    if [[ $ARTIFACTORY_IMAGE_ID == "null" ]]; then
        docker login -u $ARTIFACTORY_USER -p $ARTIFACTORY_PASSWORD $ARTIFACTORY_DOCKER_REGISTRY
        docker pull $IMAGE
        docker tag $IMAGE $IMAGE:$VERSION_ON_LAST_COMMIT
        docker push $IMAGE:$VERSION_ON_LAST_COMMIT
        docker rmi $IMAGE:$VERSION_ON_LAST_COMMIT
    else
       printinfo "L'image docker $IMAGE:$VERSION_ON_LAST_COMMIT déjà présente dans Artifactory, docker push inutile"
    fi
else
    printerror "Aucun tag trouvé sur le dernier commit $LAST_COMMIT_ID"
fi
