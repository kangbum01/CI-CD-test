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
    command: ['sh','-c','cat']   # 컨테이너 대기 (sh 스텝용)
    tty: true
    volumeMounts:
    - name: kaniko-docker-config
      mountPath: /kaniko/.docker
  - name: kubectl
    image: alpine:3.20
    command: ['sh','-c','sleep infinity']
    tty: true
  volumes:
  - name: kaniko-docker-config
    emptyDir: {}
"""
    }
  }

  // ===== 환경 변수(레포/네임스페이스/태그) =====
  environment {
    REGISTRY   = "index.docker.io"
    DOCKER_NS  = "alvin852"                 // ← 너의 Docker Hub 계정
    IMAGE_NAME = "ci-cd-test"
    IMAGE_TAG  = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
    CONTEXT    = "."
    DOCKERFILE = "Dockerfile"
  }

  stages {

    stage('Docker auth.json 생성') {
      steps {
        container('kaniko') {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                            usernameVariable: 'DH_USER',
                                            passwordVariable: 'DH_PASS')]) {
            sh '''
              set -eu
              mkdir -p /kaniko/.docker
              AUTH=$(printf "%s:%s" "$DH_USER" "$DH_PASS" | base64 -w0)
              cat > /kaniko/.docker/config.json <<EOF
              {"auths":{"https://index.docker.io/v1/":{"auth":"${AUTH}"}}}
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

    stage('Deploy to Kubernetes') {
      steps {
        container('kubectl') {
          sh '''
            set -eux
            # kubectl 설치
            apk add --no-cache curl ca-certificates
            KVER=v1.34.1
            curl -L -o /usr/local/bin/kubectl https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl
            chmod +x /usr/local/bin/kubectl

            # 매니페스트 적용(생성/갱신)
            kubectl -n ci apply -f k8s/deploy.yaml

            # 이번 빌드의 이미지 태그로 롤링 업데이트
            kubectl -n ci set image deploy/myapp myapp=index.docker.io/alvin852/ci-cd-test:${IMAGE_TAG}

            # 롤아웃 완료 대기
            kubectl -n ci rollout status deploy/myapp --timeout=120s

            # 확인
            kubectl -n ci get pods -l app=myapp -o wide
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
