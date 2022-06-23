pipelineJob('Test_GitHubToken') {
  definition {
    cps {
        sandbox(true)
        script('''
pipeline {
  agent {
    label 'agent1'
  }

  stages {
    stage("Checkout") {
      steps {
        checkout(
            poll: false,
            scm: [$class: 'GitSCM',
                branches: [[name: "main"]],
                extensions: [
                    [$class: 'CloneOption', shallow: true],
                    [$class: 'PruneStaleBranch'],
                    [$class: 'PruneStaleTag', pruneTags: true],
                ],
                userRemoteConfigs: [[credentialsId: 'github_token', url: 'https://github.com/srz-zumix/git-tips.git']]
            ]
        )
      }
    }
  }
}
''')
    }
  }
}
