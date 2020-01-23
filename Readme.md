# Gitlab Pipeline Dashboard

> Display a colored dashboard for a Gitlab project's pipelines.

### Usage

Open 2 terminal windows and navigate to the root directory of this project.

1. In one window, start up a simple web server

```sh
python -m SimpleHTTPServer
```
> This will start up a python SimpleHTTPServer on port `8000`

<br />

In the other terminal window, start the updater for the projects, whose pipelines you want to monitor

```sh
./fetcher.sh --host {{gitlab_host_url}} --token {{your_gitlab_api_token}} --projects {{comma_separated_list_of_project_ids}} --ref {{optional_git_ref_name}} --variables {{optional_flag_if_should_fetch_variables}} --jobs {{optional_flag_if_should_fetch_jobs}}
```

Example:

```sh
./fetcher.sh --host https://gitlab.example.com --token someTokenString --projects 123,456 --ref master --variables false --jobs true
```

> If no `--ref` is provided, all branches will be used.
> If `--variables` is not provided, or `false`, no variables information will be fetched
> If `--jobs` is not provided, or `false`, no jobs information will be fetched

<br />

Once the updater is running, open the browser and navigate to:

`localhost:{{port}}/?projectId={{project_id}}`

Accepted query parameters:

- `projectId`: __required__, id of the gitlab project
- `showVariables`: *optional*, a flag to determine, if a column with pipeline variables should be shown - if `1`, the column will be shown
- `variables`: *optional*, a comma-separated list of variable names, that should be shown
- `showJobs`: *optional*, a flag to determine, if a column with pipeline jobs should be shown - if `1`, the column will be shown
- `jobs`: *optional*, a comma-separated list of job names, that should be shown

Example:

`localhost:8000/?projectId=123&showVariables=1&variables=SOME_VARIABLE,OTHER_VARIABLE&showJobs=1&jobs=testJob`