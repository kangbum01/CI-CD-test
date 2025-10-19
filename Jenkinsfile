// Jenkinsfile — Multibranch + Kubernetes Agent + Kaniko (debug)
// 요구사항:
//  - Jenkins > Manage Jenkins > System > Clouds 에 Kubernetes cloud 이름이 'kubernetes' 여야 함
//  - 네임스페이스: ci
//  - ci 네임스페이스에 dockerhub-cred 시크릿 존재
//  - control-plane taint 환경 대비 tolerations 포함

pipeline {
  agent {
    kubernetes {
      cloud 'kubernetes'
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  serviceAccountName: jenkins
  # control-plane/master taint가 있는 단일노드/학습용 클러스터 대비
  tolerations:
  - key: "node-role.kubernetes.io/control-plane"
    operator: "Exists"
    effect: "NoSchedule"
  - key: "node-role.kubernetes.io/master"
    operator: "Exists"
    effect: "NoSchedule"
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest-debug
    # 기본 executor 이미지는 cat/sh 없음 → debug 태그 + busybox 셸로 대기
    command: ["/busybox/sh"]
    args: ["-c", "sleep 3650d"]
    tty: true
    resources:
      requests:
        cpu: "500m"
        memory: "1Gi"
      limits:
        cpu: "2"
        memory: "4Gi"
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

  options {
    timestamps()
    ansiColor('xterm')
    // 필요하면 전체 타임아웃:
    // timeout(time: 20, unit: 'MINUTES')
  }

  // 필요 시 GitHub Webhook 연동 시에만 활성화 (터널/도메인 준비 후)
  // triggers { githubPush() }

  environment {
    // ★ 여기를 네 도커허브 경로로 바꿔주세요
    IMAGE = 'docker.io/<DOCKER_HUB_ID>/<REPO_NAME>'
    BRANCH = env.BRANCH_NAME?.replaceAll('[^A-Za-z0-9._-]','-')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Push with Kaniko') {
      steps {
        container('kaniko') {
          script {
            def sha = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
            // main/master 브랜치면 latest도 함께 푸시, 아니면 브랜치-커밋태그만
            def isMain = (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master')
            def tag1 = "${BRANCH}-${sha}"

            sh """
              /kaniko/executor \
                --context=${WORKSPACE} \
                --dockerfile=${WORKSPACE}/Dockerfile \
                --destination=${IMAGE}:${tag1} \
                ${isMain ? "--destination=${IMAGE}:latest" : ""} \
                --snapshotMode=redo --single-snapshot
            """

            echo "Pushed tags: ${IMAGE}:${tag1}${isMain ? " and :latest" : ""}"
          }
        }
      }
    }
  }

  post {
    success {
      echo "Build SUCCESS — pushed image(s) to Docker Hub."
    }
    failure {
      echo "Build FAILED — check console logs and k8s events."
    }
    always {
      echo "Done: ${currentBuild.currentResult}"
    }
  }
}
