//pipeline {
//    agent any
//
//    options {
//        timestamps()
//        ansiColor('xterm')
//        disableConcurrentBuilds()
//        buildDiscarder(logRotator(numToKeepStr: '10'))
//    }
//
//    parameters {
//        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
//        booleanParam(name: 'RUN_TERRAFORM_APPLY', defaultValue: true, description: 'Run terraform apply')
//        booleanParam(name: 'RUN_ANSIBLE_BOOTSTRAP', defaultValue: false, description: 'Bootstrap cluster before deploy')
//        booleanParam(name: 'RUN_OWASP_ZAP', defaultValue: true, description: 'Run OWASP ZAP after deploy')
//    }
//
//    environment {
//        AWS_REGION       = 'ap-south-1'
//        AWS_ACCOUNT_ID   = '548932260906'
//        ECR_REGISTRY     = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
//
//        PROJECT_NAME     = 'gocartops'
//        EKS_CLUSTER_NAME = "gocartops-${params.ENV}-eks"
//        APP_NAMESPACE    = "gocart-${params.ENV}"
//        MONITORING_NS    = 'monitoring'
//
//        PRODUCT_SERVICE  = 'product-service'
//        ORDER_SERVICE    = 'order-service'
//
//        IMAGE_TAG        = "${params.ENV}-${BUILD_NUMBER}"
//        LATEST_TAG       = "${params.ENV}-latest"
//
//        TERRAFORM_DIR    = 'terraform'
//        ANSIBLE_DIR      = 'ansible'
//
//        SONAR_PROJECT_KEY = 'gocartops'
//        SONAR_HOST_URL    = 'http://sonarqube:9000'
//
//        // Keep empty to auto-discover from Kubernetes Ingress.
//        APP_BASE_URL      = ''
//    }
//
//    stages {
//        stage('GitHub Checkout') {
//            steps {
//                checkout scm
//                sh 'git rev-parse --short HEAD'
//                sh 'chmod +x ci/*.sh || true'
//            }
//        }
//
//        stage('SonarQube Scan') {
//            steps {
//                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
//                    sh '''
//                        sonar-scanner \
//                          -Dsonar.host.url=${SONAR_HOST_URL} \
//                          -Dsonar.login=${SONAR_TOKEN}
//                    '''
//                }
//            }
//        }
//
//        stage('Docker Build') {
//            steps {
//                sh '''
//                    ./ci/docker-build.sh \
//                      --registry "${ECR_REGISTRY}" \
//                      --tag "${IMAGE_TAG}" \
//                      --latest-tag "${LATEST_TAG}"
//                '''
//            }
//        }
//
//        stage('Twistlock / Prisma Image Scan') {
//            steps {
//                withCredentials([
//                    string(credentialsId: 'prisma-console-url', variable: 'PRISMA_CONSOLE_URL'),
//                    string(credentialsId: 'prisma-access-key', variable: 'PRISMA_ACCESS_KEY'),
//                    string(credentialsId: 'prisma-secret-key', variable: 'PRISMA_SECRET_KEY')
//                ]) {
//                    sh '''
//                        ./ci/twistlock-scan.sh \
//                          --registry "${ECR_REGISTRY}" \
//                          --tag "${IMAGE_TAG}"
//                    '''
//                }
//            }
//        }
//
//        stage('Trivy Image Scan') {
//            steps {
//                sh '''
//                    ./ci/trivy-scan.sh \
//                      --registry "${ECR_REGISTRY}" \
//                      --tag "${IMAGE_TAG}"
//                '''
//            }
//        }
//
//        stage('Docker Push to ECR') {
//            steps {
//                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
//                    credentialsId: 'aws-creds',
//                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                ]]) {
//                    sh '''
//                        aws sts get-caller-identity
//                        aws ecr get-login-password --region "${AWS_REGION}" \
//                          | docker login --username AWS --password-stdin "${ECR_REGISTRY}"
//
//                        ./ci/docker-push.sh \
//                          --registry "${ECR_REGISTRY}" \
//                          --tag "${IMAGE_TAG}" \
//                          --latest-tag "${LATEST_TAG}"
//                    '''
//                }
//            }
//        }
//
//        stage('Terraform Init / Validate / Plan') {
//            steps {
//                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
//                    credentialsId: 'aws-creds',
//                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                ]]) {
//                    dir("${TERRAFORM_DIR}") {
//                        sh '''
//                            terraform init
//                            terraform fmt -check -recursive
//                            terraform validate
//                            terraform plan -out=tfplan
//                            terraform show -json tfplan > tfplan.json
//                        '''
//                    }
//                }
//            }
//        }
//
//        stage('Checkov Scan') {
//            steps {
//                sh '''
//                    ./ci/checkov-scan.sh \
//                      --terraform-dir "${TERRAFORM_DIR}" \
//                      --plan-json "${TERRAFORM_DIR}/tfplan.json"
//                '''
//            }
//        }
//
//        stage('Terraform Apply') {
//            when {
//                expression { return params.RUN_TERRAFORM_APPLY }
//            }
//            steps {
//                script {
//                    if (params.ENV == 'prod') {
//                        input message: 'Approve Terraform apply for PROD?', ok: 'Apply'
//                    }
//                }
//                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
//                    credentialsId: 'aws-creds',
//                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                ]]) {
//                    dir("${TERRAFORM_DIR}") {
//                        sh 'terraform apply -auto-approve -parallelism=1 tfplan'
//                    }
//                }
//            }
//        }
//
//        stage('Update Kubeconfig') {
//            steps {
//                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
//                    credentialsId: 'aws-creds',
//                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                ]]) {
//                    sh '''
//                        aws eks update-kubeconfig \
//                          --region "${AWS_REGION}" \
//                          --name "${EKS_CLUSTER_NAME}"
//
//                        kubectl get nodes
//                    '''
//                }
//            }
//        }
//
//        stage('Ansible Bootstrap if Needed') {
//            when {
//                expression { return params.RUN_ANSIBLE_BOOTSTRAP }
//            }
//            steps {
//                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
//                    credentialsId: 'aws-creds',
//                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                ]]) {
//                    dir("${ANSIBLE_DIR}") {
//                        sh '''
//                            ansible-galaxy collection install -r requirements.yml
//                            ANSIBLE_ROLES_PATH=./roles ansible-playbook \
//                              -i inventory/${ENV}.ini \
//                              playbooks/bootstrap-cluster.yml \
//                              -e env=${ENV} \
//                              -e ansible_python_interpreter=/usr/bin/python3
//                        '''
//                    }
//                }
//            }
//        }
//
//        stage('Helm Deploy to EKS') {
//            steps {
//                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
//                    credentialsId: 'aws-creds',
//                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                ]]) {
//                    dir("${ANSIBLE_DIR}") {
//                        sh '''
//                            ANSIBLE_ROLES_PATH=./roles ansible-playbook \
//                              -i inventory/${ENV}.ini \
//                              playbooks/deploy.yml \
//                              -e env=${ENV} \
//                              -e ansible_python_interpreter=/usr/bin/python3
//                        '''
//                    }
//
//                    sh '''
//                        kubectl rollout status deployment/${PRODUCT_SERVICE} -n ${APP_NAMESPACE} --timeout=300s
//                        kubectl rollout status deployment/${ORDER_SERVICE} -n ${APP_NAMESPACE} --timeout=300s
//                        kubectl get pods -n ${APP_NAMESPACE} -o wide
//                    '''
//                }
//            }
//        }
//
//        stage('OWASP ZAP Scan') {
//            when {
//                expression { return params.RUN_OWASP_ZAP }
//            }
//            steps {
//                sh '''
//                    if [ -z "${APP_BASE_URL}" ]; then
//                      echo "APP_BASE_URL is empty. Trying to discover ALB URL from ingress..."
//                      DISCOVERED_URL=$(kubectl get ingress -n ${APP_NAMESPACE} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
//
//                      if [ -z "${DISCOVERED_URL}" ]; then
//                        echo "No ingress URL found. Skipping OWASP ZAP scan."
//                        exit 0
//                      fi
//
//                      export APP_BASE_URL="http://${DISCOVERED_URL}"
//                    fi
//
//                    ./ci/owasp-zap-scan.sh --target "${APP_BASE_URL}"
//                '''
//            }
//        }
//
//        stage('Prometheus / Grafana Health Check') {
//            steps {
//                sh '''
//                    echo "Checking app namespace..."
//                    kubectl get pods -n ${APP_NAMESPACE}
//                    kubectl get svc -n ${APP_NAMESPACE}
//                    kubectl get hpa -n ${APP_NAMESPACE} || true
//
//                    echo "Checking monitoring namespace..."
//                    kubectl get pods -n ${MONITORING_NS}
//                    kubectl get svc -n ${MONITORING_NS}
//
//                    echo "Checking Prometheus..."
//                    kubectl get pods -n ${MONITORING_NS} | grep prometheus || true
//
//                    echo "Checking Grafana..."
//                    kubectl get pods -n ${MONITORING_NS} | grep grafana || true
//                '''
//            }
//        }
//    }
//
//    post {
//        always {
//            archiveArtifacts artifacts: 'reports/**/*, terraform/tfplan.json', allowEmptyArchive: true
//            junit testResults: 'reports/**/*.xml', allowEmptyResults: true
//        }
//
//        success {
//            echo "Pipeline completed successfully for ${PROJECT_NAME}-${params.ENV}"
//        }
//
//        failure {
//            echo "Pipeline failed. Check the failed stage logs."
//        }
//    }
//}


/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////

//pipeline {
//    agent any
//
//    tools {
//        go 'Go-1.22'
//    }
//
//    environment {
//        PRODUCT_SERVICE_DIR = 'product-service'
//        ORDER_SERVICE_DIR   = 'order-service'
//        BUILD_DIR           = 'build-artifacts'
//    }
//
//    options {
//        timestamps()
//        ansiColor('xterm')
//        skipDefaultCheckout(false)
//    }
//
//    stages {
//
//        stage('Checkout Source Code') {
//            steps {
//                echo 'Checking out source code from GitHub...'
//                checkout scm
//            }
//        }
//
//        stage('Validate Repository Structure') {
//            steps {
//                echo 'Validating required folders and files...'
//
//                sh '''
//                    echo "Current workspace:"
//                    pwd
//
//                    echo "Repository files:"
//                    ls -la
//
//                    if [ ! -d "$PRODUCT_SERVICE_DIR" ]; then
//                      echo "ERROR: product-service folder not found"
//                      exit 1
//                    fi
//
//                    if [ ! -d "$ORDER_SERVICE_DIR" ]; then
//                      echo "ERROR: order-service folder not found"
//                      exit 1
//                    fi
//
//                    if [ ! -f "$PRODUCT_SERVICE_DIR/go.mod" ]; then
//                      echo "ERROR: product-service/go.mod not found"
//                      exit 1
//                    fi
//
//                    if [ ! -f "$ORDER_SERVICE_DIR/go.mod" ]; then
//                      echo "ERROR: order-service/go.mod not found"
//                      exit 1
//                    fi
//
//                    echo "Repository structure validation completed successfully."
//                '''
//            }
//        }
//
//        stage('Go Version Check') {
//            steps {
//                echo 'Checking Go version installed in Jenkins...'
//
//                sh '''
//                    go version
//                    go env GOPATH
//                    go env GOMODCACHE
//                '''
//            }
//        }
//
//        stage('Download Dependencies') {
//            parallel {
//                stage('Product Service Dependencies') {
//                    steps {
//                        dir("${PRODUCT_SERVICE_DIR}") {
//                            sh '''
//                                echo "Downloading product-service dependencies..."
//                                go mod download
//                                go mod tidy
//                            '''
//                        }
//                    }
//                }
//
//                stage('Order Service Dependencies') {
//                    steps {
//                        dir("${ORDER_SERVICE_DIR}") {
//                            sh '''
//                                echo "Downloading order-service dependencies..."
//                                go mod download
//                                go mod tidy
//                            '''
//                        }
//                    }
//                }
//            }
//        }
//
//        stage('Run Unit Tests') {
//            parallel {
//                stage('Product Service Tests') {
//                    steps {
//                        dir("${PRODUCT_SERVICE_DIR}") {
//                            sh '''
//                                echo "Running product-service tests..."
//                                go test ./... -v
//                            '''
//                        }
//                    }
//                }
//
//                stage('Order Service Tests') {
//                    steps {
//                        dir("${ORDER_SERVICE_DIR}") {
//                            sh '''
//                                echo "Running order-service tests..."
//                                go test ./... -v
//                            '''
//                        }
//                    }
//                }
//            }
//        }
//
//        stage('Build Go Services') {
//            steps {
//                echo 'Building Go services...'
//
//                sh '''
//                    rm -rf "$BUILD_DIR"
//                    mkdir -p "$BUILD_DIR"
//
//                    echo "Building product-service..."
//                    cd "$PRODUCT_SERVICE_DIR"
//                    go build -o "../$BUILD_DIR/product-service" .
//                    cd ..
//
//                    echo "Building order-service..."
//                    cd "$ORDER_SERVICE_DIR"
//                    go build -o "../$BUILD_DIR/order-service" .
//                    cd ..
//
//                    echo "Generated build artifacts:"
//                    ls -lh "$BUILD_DIR"
//                '''
//            }
//        }
//
//        stage('Archive Build Artifacts') {
//            steps {
//                echo 'Archiving build artifacts...'
//
//                archiveArtifacts artifacts: 'build-artifacts/*', fingerprint: true
//            }
//        }
//    }
//
//    post {
//        success {
//            echo 'Phase 1 completed successfully: GitHub checkout, Go test, Go build, and artifact archive are working.'
//        }
//
//        failure {
//            echo 'Phase 1 failed. Check the failed stage logs in Jenkins.'
//        }
//
//        always {
//            echo 'Cleaning Jenkins workspace...'
//            cleanWs()
//        }
//    }
//}


///////////////////////////////////////////////////////////////////////


pipeline {
    agent any

    stages {
        stage('Step 2 - GitHub Checkout Only') {
            steps {
                checkout scm

                sh '''
                    echo "GitHub checkout successful"
                    pwd
                    ls -la
                    git log -1 --oneline
                '''
            }
        }
    }
}