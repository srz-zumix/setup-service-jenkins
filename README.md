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
| jenkins-plugin-cli        | [jenkins-plugin-manager][] warpper. |

## Inputs

### `name`

Required. Jenkins service container name.

### `plugins`

Optional. Jenkins plugins list. Default is empty.

### `plugins_file`

Optional. Jenkins plugins list file. (.txt or .yaml|yml) Default is empty.

support [jenkins-plugin-manager][] file format.

### `install_suggested_plugins`

Optional. Install suggested plugins [true,false]. Default is false.

### `jcasc_path`

Optional. Jenkins Configuration as Code YAML path. (directory or file)

### `nodes`

Optional. Jenkins node container names.

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
        # https://hub.docker.com/r/jenkins/jenkins
        image: jenkins/jenkins:latest
        credentials:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
        # env:
        #   # Set JCasC path (default is /var/jenkins_home/casc_configs)
        #   JAVA_OPTS: -Dcasc.jenkins.config=/var/jenkins_home/jcasc
        ports:
          - 8080:8080
          - 50000:50000
      agent1:
        image: jenkins/jnlp-agent-jdk11
    steps:
    - name: clone
      uses: actions/checkout@v2
    - uses: srz-zumix/setup-service-jenkins@v1
      with:
        name: jenkins
        nodes: |
          agent1
        install_suggested_plugins: true
        plugins: |
          job-dsl
          warnings-ng
        jcasc_path: "casc_configs/"
    - name: List jobs
      run: |
        jenkins-cli list-jobs
    - name: List online nodes
      run: |
        jenkins-cli-groovy 'jenkins.model.Jenkins.get().computers.findAll{ it.isOnline() }.each { println it.displayName }'
    - name: Build job
      run: |
        jenkins-cli build "${TEST_JOB}" -s
    - name: Build log
      run: |
        jenkins-build-log "${TEST_JOB}"
      if: success() || failure()
```

[jenkins-plugin-manager]:https://github.com/jenkinsci/plugin-installation-manager-tool
