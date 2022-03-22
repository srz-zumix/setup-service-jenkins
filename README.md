# setup-service-jenkins

setup github actions services jenkins container and jenkins-cli wrapper

## Inputs

### `id`

Required. Jenkins service container id.

### `port`

Optional. Jenkins service container port. Default is `8080`.

### `plugins_file`

Optional. Jenkins plugins file. Default is empty.

### `install_suggested_plugins`

Optional. Install suggested plugins [true,false]. Default is false.

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
        env:
          # disable setup wizard + JCasC load
          JAVA_OPTS: -Djenkins.install.runSetupWizard=false -Dcasc.jenkins.config=/var/jenkins_home/casc_configs
        ports:
          - 8080:8080
          - 50000:50000
    steps:
    - name: clone
      uses: actions/checkout@v2
    - uses: srz-zumix/setup-service-jenkins@main
      with:
        id: "${{ job.services.jenkins.id }}"
        install_suggested_plugins: true
    - run: |
        jenkins-cli list-plugins
```
