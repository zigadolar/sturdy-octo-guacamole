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
./fetcher.sh {{gitlab_host_url}} {{your_gitlab_api_token}} {{comma_separated_list_of_project_ids}} {{optional_git_ref_name}}
```

Example:

```sh
./fetcher.sh https://gitlab.example.com someTokenString 123,456 master
```

> If no `branch` is provided, all branches will be used.

<br />

Once the updater is running, open the browser and navigate to:

`localhost:{{port}}/?projectId={{project_id}}`

Accepted query parameters:

- `projectId`: __required__, id of the gitlab project
- `showVariables`: *optional*, a flag to determine, if a column with pipeline variables should be shown - if `1`, the column will be shown
- `variables`: *optional*, a comma-separated list of variable names, that should be shown

Example:

`localhost:8000/?projectId=123&showVariables=1&variables=SOME_VARIABLE,OTHER_VARIABLE`