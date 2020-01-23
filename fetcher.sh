#!/bin/bash

# get arguments from command line
# currently supported:
# `--host https://gitlab.example.com` 
# `--token someTokenString`
# `--projects 123,456`
# `--ref some_branch`
# `--variables true/false`
# `--jobs true/false`

while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare $v="$2"
    fi
    shift
done

if ! [[ ${host} ]]; then
  echo "Missing Gitlab host url"
  exit 1
fi

if ! [[ ${token} ]]; then
  echo "Missing token"
  exit 1
fi

if ! [[ ${projects} ]]; then
  echo "Missing project id(s)"
  exit 1
fi

if [[ ${#ref} -gt 0 ]]; then
  REF="&ref=${ref}"
else
  REF=""
fi

GET_VARIABLES=false

if [[ $variables ]]; then
  if [[ $variables = "true" ]]
    then
        GET_VARIABLES=true
    fi
fi

GET_JOBS=false

if [[ $jobs ]]; then
  if [[ $jobs = "true" ]]
    then
        GET_JOBS=true
    fi
fi

rm -rf data
mkdir -p data

PROJ_FILE="data/projects.json"

echo "{" > $PROJ_FILE
for project_id in ${projects//,/ }; do
  echo "Fetching project info for ${project_id}"
  js=$(curl -sS --header "PRIVATE-TOKEN: ${token}" "${host}/api/v4/projects/${project_id}")
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
  for project_id in ${projects//,/ }; do
    echo "Fetching pipelines for ${project_id}"
    project_dir="data/projects/${project_id}"
    project_json="${project_dir}.json"
    curl -sS --header "PRIVATE-TOKEN: ${token}" "${host}/api/v4/projects/${project_id}/pipelines?order_by=updated_at${REF}" -o ${project_json}

    pipelines_dir="${project_dir}/pipelines"
    mkdir -p ${pipelines_dir}

    grep_param='P'

    if [[ "$OSTYPE" == "darwin"* ]]; then
      grep_param='E'
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
      grep_param='E'
    fi

    pipeline_ids=$(grep -${grep_param}o '"id":\d*?[^\\],' ${project_json})

    if [[ $GET_VARIABLES = true ]]; then
      for pipeline_id in ${pipeline_ids//,/ }; do
        id=$(echo ${pipeline_id} | sed 's/"id":\(\d*\)/\1/')

        pipeline_dir="${pipelines_dir}/${id}"
        mkdir -p ${pipeline_dir}

        variables_json="${pipeline_dir}/variables.json"
        if ! [[ -f "$variables_json" ]]; then
          echo "Fetching variables for pipeline ${id} for project ${project_id}"
          curl -sS --header "PRIVATE-TOKEN: ${token}" "${host}/api/v4/projects/${project_id}/pipelines/${id}/variables" -o ${variables_json}
        fi
      done
    fi

    if [[ $GET_JOBS = true ]]; then
      for pipeline_id in ${pipeline_ids//,/ }; do
        id=$(echo ${pipeline_id} | sed 's/"id":\(\d*\)/\1/')

        pipeline_dir="${pipelines_dir}/${id}"
        mkdir -p ${pipeline_dir}

        jobs_json="${pipeline_dir}/jobs.json"
        if ! [[ -f "$jobs_json" ]]; then
          echo "Fetching jobs for pipeline ${id} for project ${project_id}"
          curl -sS --header "PRIVATE-TOKEN: ${token}" "${host}/api/v4/projects/${project_id}/pipelines/${id}/jobs" -o ${jobs_json}
        fi
      done
    fi
  done

  echo "Sleeping ..."
  sleep 60
done