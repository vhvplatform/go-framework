# CI/CD Integration Examples

Examples of integrating go-framework with various CI/CD platforms.

## GitHub Actions

### Complete Test Workflow

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Install dependencies
        run: |
          cd framework
          ./scripts/setup/install-tools.sh
      
      - name: Start services
        run: |
          cd framework
          make start
      
      - name: Wait for services
        run: |
          cd framework
          ./scripts/dev/wait-for-services.sh
      
      - name: Run unit tests
        run: |
          cd framework
          make test-unit
      
      - name: Run integration tests
        run: |
          cd framework
          make test-integration
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.out
```

### Build and Push Docker Images

```yaml
# .github/workflows/build.yml
name: Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Docker meta
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: vhvplatform/my-service
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        run: |
          cd framework
          make docker-build
          make docker-push
```

## GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  GO_VERSION: "1.21"

before_script:
  - cd framework

test:
  stage: test
  image: golang:${GO_VERSION}
  services:
    - docker:dind
  script:
    - make setup-tools
    - make start
    - make test
  coverage: '/coverage: \d+.\d+%/'

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - make docker-build
    - make docker-push
  only:
    - main
    - tags

deploy-dev:
  stage: deploy
  script:
    - make deploy-dev
  environment:
    name: development
  only:
    - develop
```

## Jenkins

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        GO_VERSION = '1.21'
        DOCKER_REGISTRY = 'registry.example.com'
    }
    
    stages {
        stage('Setup') {
            steps {
                sh '''
                    cd framework
                    ./scripts/setup/install-tools.sh
                '''
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'cd framework && make test-unit'
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh '''
                            cd framework
                            make start
                            make test-integration
                        '''
                    }
                }
            }
        }
        
        stage('Build') {
            when {
                branch 'main'
            }
            steps {
                sh 'cd framework && make docker-build'
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh 'cd framework && make deploy-dev'
            }
        }
    }
    
    post {
        always {
            sh 'cd framework && make clean'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

## CircleCI

```yaml
# .circleci/config.yml
version: 2.1

orbs:
  go: circleci/go@1.7

jobs:
  test:
    docker:
      - image: cimg/go:1.21
    steps:
      - checkout
      - setup_remote_docker
      - run:
          name: Install tools
          command: |
            cd framework
            ./scripts/setup/install-tools.sh
      - run:
          name: Start services
          command: |
            cd framework
            make start
      - run:
          name: Run tests
          command: |
            cd framework
            make test
      - store_test_results:
          path: ./test-results

  build:
    docker:
      - image: docker:latest
    steps:
      - checkout
      - setup_remote_docker
      - run:
          name: Build images
          command: |
            cd framework
            make docker-build

workflows:
  version: 2
  test-and-build:
    jobs:
      - test
      - build:
          requires:
            - test
          filters:
            branches:
              only: main
```

## Travis CI

```yaml
# .travis.yml
language: go

go:
  - "1.21"

services:
  - docker

before_install:
  - cd framework
  - ./scripts/setup/install-tools.sh

script:
  - make start
  - make test

after_success:
  - bash <(curl -s https://codecov.io/bash)

deploy:
  provider: script
  script: make docker-build && make docker-push
  on:
    branch: main
```

## Drone CI

```yaml
# .drone.yml
kind: pipeline
type: docker
name: default

steps:
  - name: test
    image: golang:1.21
    commands:
      - cd framework
      - make setup-tools
      - make start
      - make test

  - name: build
    image: plugins/docker
    settings:
      repo: vhvplatform/my-service
      tags: [ latest, ${DRONE_TAG} ]
      username:
        from_secret: docker_username
      password:
        from_secret: docker_password
    when:
      event: tag
```

## Best Practices

1. **Cache Dependencies**
   ```yaml
   - name: Cache Go modules
     uses: actions/cache@v3
     with:
       path: ~/go/pkg/mod
       key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
   ```

2. **Parallel Testing**
   ```yaml
   strategy:
     matrix:
       test: [unit, integration, e2e]
   ```

3. **Environment Variables**
   ```yaml
   env:
     JWT_SECRET: ${{ secrets.JWT_SECRET }}
     MONGODB_URI: ${{ secrets.MONGODB_URI }}
   ```

4. **Conditional Deployment**
   ```yaml
   if: github.ref == 'refs/heads/main'
   ```

5. **Clean Up**
   ```yaml
   - name: Clean up
     if: always()
     run: make clean
   ```

## See Also

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI Documentation](https://docs.gitlab.com/ee/ci/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
