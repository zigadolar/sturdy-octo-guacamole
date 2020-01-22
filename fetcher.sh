#!/bin/bash

gitlab_host="${1}"
shift
token="${1}"
shift
project_ids="${1}"
shift
ref="${1}"

if ! [[ ${gitlab_host} ]]; then
  echo "Missing Gitlab host url"
  exit 1
fi

if ! [[ ${token} ]]; then
  echo "Missing token"
  exit 1
fi

if ! [[ ${project_ids} ]]; then
  echo "Missing project id(s)"
  exit 1
fi

if [[ ${#ref} -gt 0 ]]; then
  REF="&ref=${ref}"
else
  REF=""
fi

rm -rf data
mkdir -p data

PROJ_FILE="data/projects.json"

echo "{" > $PROJ_FILE
for project_id in ${project_ids//,/ }; do
  echo "Fetching project info for ${project_id}"
  js=$(curl -sS --header "PRIVATE-TOKEN: ${token}" "${gitlab_host}/api/v4/projects/${project_id}")
  rx='"name_with_namespace":"([^"]*)"'
  if [[ "$js" =~ $rx ]]; then
    result="${BASH_REMATCH[1]}"
    echo "\"${project_id}\":\"${result}\"," >> $PROJ_FILE
  fi;
done
sed '$ s/,$//' $PROJ_FILE > "${PROJ_FILE}.tmp" && mv "${PROJ_FILE}.tmp" $PROJ_FILE
echo "}" >> $PROJ_FILE

mkdir -p data/projects
while true
do
  for project_id in ${project_ids//,/ }; do
    echo "Fetching pipelines for ${project_id}"
    project_dir="data/projects/${project_id}"
    project_json="${project_dir}.json"
    curl -sS --header "PRIVATE-TOKEN: ${token}" "${gitlab_host}/api/v4/projects/${project_id}/pipelines?order_by=updated_at${REF}" -o ${project_json}

    pipelines_dir="${project_dir}/pipelines"
    mkdir -p ${pipelines_dir}
    pipeline_ids=$(grep -Eo '"id":\d*?[^\\],' ${project_json})

    for pipeline_id in ${pipeline_ids//,/ }; do
      id=$(echo ${pipeline_id} | sed 's/"id":\(\d*\)/\1/')

      pipeline_dir="${pipelines_dir}/${id}"
      mkdir -p ${pipeline_dir}

      variables_json="${pipeline_dir}/variables.json"
      if ! [[ -f "$variables_json" ]]; then
        echo "Fetching variables for pipeline ${id} for project ${project_id}"
        curl -sS --header "PRIVATE-TOKEN: ${token}" "${gitlab_host}/api/v4/projects/${project_id}/pipelines/${id}/variables" -o ${variables_json}
      fi
    done
  done

  echo "Sleeping ..."
  sleep 60
done