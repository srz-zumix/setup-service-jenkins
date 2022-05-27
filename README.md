# setup-service-jenkins

setup github actions services jenkins container and jenkins-cli wrapper

| command                   | summary                 |
|:--------------------------|:------------------------|
| jenkins-build-log         | Print jenkins build log. |
| jenkins-cli               | jenkins-cli.jar wrapper (java -jar jenkin-cli.jar -s SERVICE_JENKINS_URL) |
| jenkins-cli-groovy        | Executes the specified Groovy script. |
| jenkins-cli-groovyfile    | Executes the specified Groovy script file. |
| jenkins-credential        | Add to jenkins credential. |
| jenkins-download-artifact | Download jenkins job artifact. |
| jenkins-log               | Print service jenkins docker logs. |

## Inputs

### `id`

Required. Jenkins service container id.

### `port`

Optional. Jenkins service container port. Default is `8080`.

### `plugins`

Optional. Jenkins plugins list. Default is empty.

### `plugins_file`

Optional. Jenkins plugins list file. Default is empty.

### `install_suggested_plugins`

Optional. Install suggested plugins [true,false]. Default is false.

### `jcasc_path`

Optional. Jenkins Configuration as Code YAML path. (directory or file)

### `github_token`

Optional. GITHUB_TOKEN add to jenkins credential. (id = github_token)

## Example usage

### [github-actions-sample](https://github.com/srz-zumix/github-actions-sample)

[reviewdog-jflint.yml](https://github.com/srz-zumix/github-actions-sample/blob/main/.github/workflows/reviewdog-jflint.yml)

### [.github/workflows/pr_test.yml](.github/workflows/pr_test.yml)

```yml
name: Example
on: [pull_request]

jobs:
  setup-jenkins:
    runs-on: ubuntu-latest
    services:
      jenkins:
        image: jenkins/jenkins:lts-jdk11
        credentials:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
        # env:
        #   # Set JCasC path (default is /var/jenkins_home/casc_configs)
        #   JAVA_OPTS: -Dcasc.jenkins.config=/var/jenkins_home/jcasc
        ports:
          - 8080:8080
          - 50000:50000
    steps:
    - name: clone
      uses: actions/checkout@v2
    - uses: srz-zumix/setup-service-jenkins@v1
      with:
        id: "${{ job.services.jenkins.id }}"
        install_suggested_plugins: true
        plugins: |
          job-dsl
          warnings-ng
        jcasc_path: "casc_configs/"
    - run: |
        jenkins-cli list-plugins
```
