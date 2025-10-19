pipeline {
  agent {
    kubernetes {
      cloud 'kubernetes'
      defaultContainer 'kaniko'
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels: { ci: kaniko }
spec:
  serviceAccountName: jenkins
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:latest
      command: ["/busybox/sh"]
      args: ["-c","sleep 3650d"]
      tty: true
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
  volumes:
    - name: docker-config
      projected:
        sources:
          - secret:
              name: dockerhub-cred
              items:
                - key: .dockerconfigjson
                  path: config.json
"""
    }
  }
  environment {
    REGISTRY_IMAGE = 'docker.io/alvin852/sample-app'
  }
  options { timestamps() }
  triggers { githubPush() }    // 웹훅으로 자동 트리거
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Build & Push with Kaniko') {
      steps {
        container('kaniko') {
          script {
            def sha = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
            sh """
              /kaniko/executor \
                --context=${WORKSPACE} \
                --dockerfile=${WORKSPACE}/Dockerfile \
                --destination=${REGISTRY_IMAGE}:${sha} \
                --destination=${REGISTRY_IMAGE}:latest \
                --snapshotMode=redo --single-snapshot
            """
            echo "Pushed: ${REGISTRY_IMAGE}:${sha} and :latest"
          }
        }
      }
    }
  }
}

