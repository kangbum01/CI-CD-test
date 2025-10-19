pipeline {
  agent {
    kubernetes {
      // Jenkins가 ci 네임스페이스에 임시 에이전트 Pod 띄움
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: kaniko-build
spec:
  serviceAccountName: jenkins
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ['sh', '-c', 'cat']   # 컨테이너를 대기상태로 유지해 sh 스텝 사용
    tty: true
    volumeMounts:
    - name: kaniko-docker-config
      mountPath: /kaniko/.docker   # 여기에 auth.json 생성
  volumes:
  - name: kaniko-docker-config
    emptyDir: {}
"""
    }
  }

  // ===== 환경 변수(레포/네임스페이스/태그) =====
  environment {
    REGISTRY   = "index.docker.io"
    DOCKER_NS  = "kangbum01"    // 예: kangbum01  ← 반드시 네 계정으로!
    IMAGE_NAME = "ci-cd-test"          // 생성될 리포지토리 이름
    IMAGE_TAG  = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}" // 브랜치-빌드번호
    CONTEXT    = "."                    // 빌드 컨텍스트(레포 루트)
    DOCKERFILE = "Dockerfile"
  }

  stages {

    stage('Docker auth.json 생성') {
      steps {
        container('kaniko') {
          // Jenkins 자격증명(dockerhub-creds)을 환경변수로 바인딩
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                            usernameVariable: 'DH_USER',
                                            passwordVariable: 'DH_PASS')]) {
            sh '''
              set -eu
              mkdir -p /kaniko/.docker
              AUTH=$(printf "%s:%s" "$DH_USER" "$DH_PASS" | base64 -w0)
              cat > /kaniko/.docker/config.json <<EOF
              {
                "auths": {
                  "https://index.docker.io/v1/": { "auth": "${AUTH}" }
                }
              }
EOF
              echo "[INFO] wrote /kaniko/.docker/config.json"
            '''
          }
        }
      }
    }

    stage('Kaniko Build & Push') {
      steps {
        container('kaniko') {
          sh '''
            set -eux
            /kaniko/executor \
              --context "${CONTEXT}" \
              --dockerfile "${DOCKERFILE}" \
              --destination ${REGISTRY}/${DOCKER_NS}/${IMAGE_NAME}:${IMAGE_TAG} \
              --destination ${REGISTRY}/${DOCKER_NS}/${IMAGE_NAME}:latest
          '''
        }
      }
    }

  } // stages

  post {
    success {
      echo "Pushed: ${REGISTRY}/${DOCKER_NS}/${IMAGE_NAME}:${IMAGE_TAG}"
    }
    always {
      echo "Build URL: ${env.BUILD_URL}"
    }
  }
}
