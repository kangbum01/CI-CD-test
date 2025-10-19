pipeline {
  agent {
    kubernetes {
<<<<<<< HEAD
      cloud 'kubernetes'
=======
      cloud 'kubernetes'          // Jenkins → Manage Jenkins → Clouds에서 이름이 'kubernetes'인지 확인
>>>>>>> ec62c97 (first commit)
      defaultContainer 'kaniko'
      yaml """
apiVersion: v1
kind: Pod
metadata:
<<<<<<< HEAD
  labels: { ci: kaniko }
=======
  labels:
    ci: kaniko
>>>>>>> ec62c97 (first commit)
spec:
  serviceAccountName: jenkins
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:latest
      command: ["/busybox/sh"]
<<<<<<< HEAD
      args: ["-c","sleep 3650d"]
=======
      args: ["-c", "sleep 3650d"]
>>>>>>> ec62c97 (first commit)
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
<<<<<<< HEAD
    REGISTRY_IMAGE = 'docker.io/alvin852/sample-app'
  }
  options { timestamps() }
  triggers { githubPush() }    // 웹훅으로 자동 트리거
  stages {
    stage('Checkout') { steps { checkout scm } }
=======
    REGISTRY_IMAGE = 'docker.io/alvin852/sample-app'   // <- 네 계정/레포
  }
  options { timestamps() }
  triggers { githubPush() } // GitHub Webhook과 연동 시 자동 트리거
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
>>>>>>> ec62c97 (first commit)
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
