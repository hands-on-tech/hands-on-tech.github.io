---
layout: post
title:  "Flexible CI/CD with with Kubernetes, Helm, Traefik, Jenkins and Kotlin"
subtitle: ""
date:   2019-10-06 10:00:00 +0100
author: david_campos
tags: kubernetes k8s cluster helm traefik ingress continuos integration deployment ci/cd jenkins kotlin
comments: true
read_time: true
background: '/assets/k8s-jenkins-example/background.jpg'
math: true
---

# TL;DR
Let's create a **CI/CD** (Continuous Integration and Continuos Deployment) solution on top of **Kubernetes**, using **Jenkins** as building tool and **Traefik** as ingress for flexible application deployment and routing.

**Source code is available on [Github](https://github.com/davidcampos/k8s-jenkins-example)** with example application and supporting files.

# Goal
The main goal is to present a **flexible CI/CD solution** on top of **Kubernetes**, with **automatic** application **deployment**, **host definition and routing** per environment. To make this process easy to understand, the following steps are presented and described in detail:
1. Setup Kubernetes and understand its basic concepts;
2. Install Traefik, Dashboard and Jenkins using Helm;
3. Create Kotlin application to show how CI/CD can be used;
4. Implement Jenkins pipeline to build and deploy application automatically.

To fulfill the mentioned steps and validate the presented CI/CD solution, the architecture with the following components is proposed:
- **Kubernetes**: for containers management and orchestration;
- **Traefik**: as proxy and load balancer to access services;
- **Dashboard**: to manage Kubernetes through a web-based interface;
- **Jenkins**: as automation server to automatically build and deploy application;
- **GitHub**: to manage source code using Git;
- **DockerHub**: as registry to manage the Docker image with the example application;
- **Application stating**: example application deployment for development and testing purposes;
- **Application production**: example application deployment to be used in production.

![Components](/assets/k8s-jenkins-example/components.svg){: .image-center .img-thumbnail}
***Figure:** Components.*

Behind the curtains and as supporting tools, the following technologies are also used:
- **Docker**: for services and applications containerization;
- **Helm**: for simplified services deployment and configuration on Kubernetes;
- **Kotlin**: to develop the example application, which will be automatically built and deployed to Kubernetes.

Regarding the CI/CD solution, this post will focus in two main interaction workflows, which are presented in the sequence diagram below:
1. **Build and deploy application**: checkout latest source code version to build application and deploy it on Kubernetes cluster;
2. **Access application**: use proxy for standardized access to deployed application on specific hostname.

![Sequence](/assets/k8s-jenkins-example/sequence.svg){: .image-center .img-thumbnail}
***Figure:** Sequence diagram.*

# Kubernetes
[Kubernetes](https://kubernetes.io), also known as K8s, is the current standard solution for containers orchestration, allowing to easily deploy and manage large-scale applications in the cloud with high scalability, availability and automation level.
Kubernetes was originally developed at Google, receiving a lot of attention from the open source community. It is the main project of the [Cloud Native Computing Foundation](https://www.cncf.io) and some of the biggest players are supporting it, such as Google, Amazon, Microsoft and IBM. Out of curiosity, Kubernetes is currently one of the [top open source projects](https://github.com/cncf/velocity/tree/master/reports), being the one with highest activity in front of Linux.
Nowadays, several companies already provide production-ready Kubernetes clusters, such as AWS from Amazon, Azure from Microsoft and GCE from Google. An official list of existing Cloud Providers is provided in the [Kubernetes documentation](https://kubernetes.io/docs/concepts/cluster-administration/cloud-providers/).

## Terminology
To understand how applications can be deployed, it is fundamental to introduce some of the core concepts, which are presented and briefly described below:
- **Namespace**: a virtual cluster that can sit on top of the same physical cluster hardware, enabling concern separation across development teams;
- **Pod**: is the smallest deployable unit with a group of containers that share the same resources, such as memory, CPU and IP;
- **Replica Set**: ensures that a specified number of Pod replicas are running at any given time;
- **Deployment**: a set of multiple identical Pods, defining how to run multiple replicas of the application, how to automatically replace any instances that fail or become unresponsive, and how to perform updates;
- **Service**: abstraction of a logical set of Pods, which is the only interface that other applications use to interact with;
- **Ingress**: to manage how external access to services is provided;
- **Persistent Volume**: a piece of storage used to persist data beyond the lifetime of a Pod.

![Kubernetes Concepts](/assets/k8s-jenkins-example/kubernetes-deployment.svg){: .image-center .img-thumbnail width="80%"}
***Figure:** Kubernetes deployment concepts.*

## Architecture
Before jumping into installing and configuring Kubernetes, it is important to understand the software and hardware components required to setup a cluster properly. The figure below summarizes the required components architecture, together with a brief description of the role of each one:
- **Master**: responsible for maintaining the desired cluster state, being the entry point for administrators to manage the various nodes. The following software components run in the master:
  - ***API Server***: REST API that exposes all operations that can be performed on the cluster, such as creating, configuring and removing Pods and Services;
  - ***Scheduler***: responsible for assigning tasks to the various cluster nodes;
  - ***Controller-Manager***: to make sure that the cluster state is operating as expected, reacting to events triggered by controllers from throughout the cluster;
  - ***etcd***: distributed key-value store used to share information regarding cluster state, which can be accessed by all cluster nodes;
- **Node**: physical or virtualized machine that performs a given task, with the following components running:
  - ***Docker***: container runtime responsible for starting and managing containers;
  - ***Kubelet***: tracks the state of a Pod to ensure that all the containers are running as expected;
  - ***Kube-proxy***: routes traffic coming into a node from the service;
- **UI**: user interface application to manage cluster configurations and applications. Kubernetes Dashboard will be used in this post;
- **CLI**: command line interfaces to manage cluster configurations and applications. Kubectl will be used in this post;

![Kubernetes Architecture](/assets/k8s-jenkins-example/kubernetes-architecture.png){: .image-center .img-thumbnail width="80%"}
***Figure:** Kubernetes architecture. Source <https://blog.sensu.io/how-kubernetes-works>.*

To learn more about Kubernetes architecture and terminology, several pages already provide an in-depth description, such as the 
[Official Kubernetes Documentation](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/),
the introduction by [Digital Ocean](https://www.digitalocean.com/community/tutorials/an-introduction-to-kubernetes)
and the terminology presentation by [Daniel Sanche](https://medium.com/google-cloud/kubernetes-101-pods-nodes-containers-and-clusters-c1509e409e16).

## Install
There are several options available that make the process of installing Kubernetes more straightforward, since installing and configuring every single component can be an time consuming task. [Ramit Surana](https://github.com/ramitsurana/awesome-kubernetes#installers) provides an extensive list of such installers. Special emphasis to [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm), [kops](https://github.com/kubernetes/kops), [minikube](https://github.com/kubernetes/minikube) and [k3s](https://k3s.io), which are continuously supported and updated by the open source community.

Since I am using MacOS and want to run Kubernetes locally in a single node, decided to take advantage of [Docker Desktop](https://www.docker.com/products/docker-desktop), which already provides Docker and Kubernetes installation in a single tool. After installing, one can check the system tray menu to make sure that Kubernetes is running as expected:

![Docker Desktop](/assets/k8s-jenkins-example/docker-desktop.png){: .image-center .img-thumbnail  width="24%"}
***Figure:** Docker Desktop.*


# Kubectl
[Kubectl](https://github.com/kubernetes/kubectl) is the official CLI tool to manage a Kubernetes cluster, which can be used to deploy applications, inspect and manage cluster resources and view logs. 

Docker Desktop already installs kubectl, 
```bash
brew install kubectl 
```

```bash
kubectl version
kubectl get pods
```

![Kubectl](/assets/k8s-jenkins-example/kubectl-pods.png){: .image-center .img-thumbnail  width="60%"}
***Figure:** Kubectl.*


If you use the [ZSH](https://ohmyz.sh/) shell, keep in mind to use the [kubectl plugin](https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/kubectl/kubectl.plugin.zsh), in order to have proper highlight and auto-completion. To enable it, edit the 

Enable ohmyzsh plugin
vim ~/.zshrc
plugins=(git kubectl)

# Helm
[Helm](https://helm.sh) 
[Helm hub](https://hub.helm.sh)

- Install Helm

# Traefik
[Traefik](https://traefik.io) is a widely used proxy and load balancer for HTTP and TCP applications, natively compliant and optimized for Cloud-based solutions. In summary, Traefik analyzes the infrastructure and services configuration and automatically discovers the right configuration for each one, enabling automatic applications deployment and routing. On top of this, Traefik also supports collecting detailed metrics, logs and traceability.

![Traefik Architecture](/assets/k8s-jenkins-example/traefik-architecture.svg){: .image-center .img-thumbnail  width="80%"}
***Figure:** Traefik architecture. Source <https://docs.traefik.io>.*

[Traefik offers a stable and official Helm chart](https://github.com/helm/charts/tree/master/stable/traefik) that can be used for straightforward installation and configuration on Kubernetes.
The following configuration values are provided to the chart, in order to:
- **Dashboard**: enable access to dashboard through the domain "traefik.localhost", using the admin as username and password;
- **SSL**: enable and enforce SSL for all proxied services, with automatically generated wildcard SSL certificate for the "*.localhost" domain.

```yaml
dashboard:
  enabled: true
  domain: traefik.localhost
  auth:
    basic:
      admin: $2y$05$kpCJY2gJWlgG5CUs5tdPx.2xGJ4xyqhWtjiiM/NKfHmj3pfUPsap2
ssl:
  enabled: true
  enforced: true
  permanentRedirect: true
  generateTLS: true
  defaultCN: "*.localhost"
```
***Code:** Configuration values to use with Traefik Helm chart.*

After saving the configuration values in the file "traefik-values.yml", Traefik can be installed by executing the following command:
```bash
helm install stable/traefik --name traefik --values traefik-values.yml
```

If you would like to delete Traefik, the following command should help:
```bash
helm del --purge traefik
```

Check installation progress by checking the status of deployments and pods:
```bash
kubectl get deployments
kubectl get pods
```

When the deployment ready status is "1/1" (1 ready out of 1 required), visit <http://traefik.localhost/> to access the dashboard and login with previously defined username and password. In the dashboard one can check the entry points (frontends) available to access the deployed services (backends).

![Traefik Dashboard](/assets/k8s-jenkins-example/traefik-dashboard.png){: .image-center .img-thumbnail}
***Figure:** Traefik dashboard.*

# Kubernetes Dashboard

[Kubernetes Dashboard](https://github.com/kubernetes/dashboard) is an open-source web interface to quickly manage a Kubernetes cluster, providing user-friendly features to manage and troubleshoot deployed applications. The following configurations are provided to enable the Traefik ingress and make the dashboard available through "dashboard.localhost".

```yaml
enableInsecureLogin: true
service:
  externalPort: 9090
ingress:
  enabled: true
  hosts: 
    - dashboard.localhost
  paths: 
    - /
  annotations:
    kubernetes.io/ingress.class: traefik
```
***Code:** Configuration values to use with Kubernetes Dashboard Helm chart.*


Similarly to Traefik, the Dashboard can be installed using the [official Kubernetes Dashboard Helm chart](https://github.com/helm/charts/tree/master/stable/kubernetes-dashboard) through the commands:
```bash
helm install stable/kubernetes-dashboard --name dashboard --values dashboard-values.yml
```

In order to login,
Get secrets:
```bash
kubectl get secrets
```

![Kubernetes Secrets](/assets/k8s-jenkins-example/kubernetes-secrets.png){: .image-center .img-thumbnail width="65%"}
***Figure:** Kubernetes Dashboard.*

Get token:
```bash
kubectl describe secrets dashboard-kubernetes-dashboard-token-sk68z
```

![Kubernetes Secret](/assets/k8s-jenkins-example/kubernetes-secret.png){: .image-center .img-thumbnail width="80%"}
***Figure:** Kubernetes Dashboard.*

Dashboard:
![Kubernetes Dashboard](/assets/k8s-jenkins-example/kubernetes-dashboard.png){: .image-center .img-thumbnail}
***Figure:** Kubernetes Dashboard.*


# Jenkins

[Jenkins](https://jenkins.io)

```yaml
master:
  useSecurity: true
  adminUser: admin
  adminPassword: admin
  numExecutors: 1
  installPlugins:
    - kubernetes:1.21.1
    - workflow-job:2.36
    - workflow-aggregator:2.6
    - credentials-binding:1.20
    - git:3.12.1
    - command-launcher:1.3
    - github-branch-source:2.5.8
    - docker-workflow:1.21
    - pipeline-utility-steps:2.3.1
  overwritePlugins: true
  ingress:
    enabled: true
    hostName: jenkins.localhost
    annotations:
      kubernetes.io/ingress.class: traefik
```
***Code:** Configuration values to use with Jenkins Helm chart.*

```bash
helm install stable/jenkins --name jenkins --values jenkins-values.yml
helm del --purge jenkins
```

Dashboard:
![Jenkins Dashboard](/assets/k8s-jenkins-example/jenkins-dashboard.png){: .image-center .img-thumbnail}
***Figure:** Jenkins Dashboard.*

- Pipeline Utility steps: to get version from maven XML
- github-branch-source: to configure GitHub source code provider

# Application
[Spring Boot](https://spring.io/projects/spring-boot)
[Kotlin](https://kotlinlang.org)
[Spring Initializr](https://start.spring.io)

- Spring Boot 2.2.1
- Site to generate source

```kotlin
@RestController
class GreetingController {
    val counter = AtomicLong()
    
    @GetMapping("/greeting")
    fun greeting(@RequestParam(value = "name", defaultValue = "World") name: String): Greeting {
        val envVar: String = System.getenv("EXAMPLE_VALUE") ?: "default_value"
        return Greeting(counter.incrementAndGet(), "Hello, $name", envVar)
    }
}
```


## Dockerfile

```Dockerfile
FROM openjdk:8-jdk-alpine
EXPOSE 8090
ADD /target/k8s-jenkins-example*.jar k8s-jenkins-example.jar
ENTRYPOINT ["java", "-jar", "k8s-jenkins-example.jar"]
```

## Helm
Helm chart skeleton

![Helm chart tree](/assets/k8s-jenkins-example/helm-tree.png){: .image-center .img-thumbnail}
***Figure:** Helm chart folder and file tree.*

Run Helm create to create baseline skeleton
```bash
helm create helm
```

Values:
```yaml
image:
  repository: davidcampos/k8s-jenkins-example
  tag: latest
  pullPolicy: Always

name: "example"
domain: "localhost"

replicaCount: 1

service:
  port: 8090

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: traefik
  hosts:
    - host:
      paths:
        - /
```

[Harbor](https://goharbor.io)
You can use Harbor to deploy and re-use your own charts

On the time of writing the post, [Helm released v3](https://helm.sh/blog/helm-3-released/), which kept the same core functionality but removing the Tiller component, which significantly improves compatibility with Kubernetes RBAC system.

## Pipeline

Build Pod:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: pod
spec:
  containers:
    - name: maven
      image: maven:3.3.9-jdk-8-alpine
      command:
        - cat
      tty: true
      volumeMounts:
        - name: m2
          mountPath: /root/.m2
    - name: docker
      image: docker:19.03
      command:
        - cat
      tty: true
      privileged: true
      volumeMounts:
        - name: dockersock
          mountPath: /var/run/docker.sock
    - name: helm
      image: lachlanevenson/k8s-helm:v2.15.2
      command:
        - cat
      tty: true
  volumes:
    - name: dockersock
      hostPath:
        path: /var/run/docker.sock
    - name: m2
      hostPath:
        path: /root/.m2

```

Jenkinsfile with Declarative syntax

```groovy
pipeline {
    environment {
        DEPLOY = "${env.BRANCH_NAME == "master" || env.BRANCH_NAME == "develop" ? "true" : "false"}"
        NAME = "${env.BRANCH_NAME == "master" ? "example" : "example-staging"}"
        VERSION = readMavenPom().getVersion()
        DOMAIN = 'localhost'
        REGISTRY = 'davidcampos/k8s-jenkins-example'
        REGISTRY_CREDENTIAL = 'dockerhub-davidcampos'
    }
    agent {
        kubernetes {
            defaultContainer 'jnlp'
            yamlFile 'build.yaml'
        }
    }
    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn package'
                }
            }
        }
        stage('Docker Build') {
            when {
                environment name: 'DEPLOY', value: 'true'
            }
            steps {
                container('docker') {
                    sh "docker build -t ${REGISTRY}:${VERSION} ."
                }
            }
        }
        stage('Docker Publish') {
            when {
                environment name: 'DEPLOY', value: 'true'
            }
            steps {
                container('docker') {
                    withDockerRegistry([credentialsId: "${REGISTRY_CREDENTIAL}", url: ""]) {
                        sh "docker push ${REGISTRY}:${VERSION}"
                    }
                }
            }
        }
        stage('Kubernetes Deploy') {
            when {
                environment name: 'DEPLOY', value: 'true'
            }
            steps {
                container('helm') {
                    sh 'helm init --client-only --skip-refresh'
                    sh "helm upgrade --install --force --set name=${NAME} --set image.tag=${VERSION} --set domain=${DOMAIN} ${NAME} ./helm"
                }
            }
        }
    }
}
```


install --wait issue: https://github.com/helm/helm/issues/2426
be carefull with helm, use it for simple tasks only: https://medium.com/virtuslab/think-twice-before-using-helm-25fbb18bc822

# Job
- Create Multibranch Pipeline job
- Add GitHub branch source
- Keep default values
- Show Jenkins Job configuration


![Job](/assets/k8s-jenkins-example/jenkins-job.png){: .image-center .img-thumbnail}
***Figure:** Jenkins job configuration.*

# Check
- 

![GIF](/assets/k8s-jenkins-example/fun.gif){: .image-center}

# Conclusion

![Success](/assets/k8s-jenkins-example/conclusion.png){: .image-center .img-thumbnail}
***Figure:** The path to success.*

So I hope that this post helps you to easily build your Jenkins pipelines with Kubernetes.

Please remember that your comments, suggestions and contributions are more than welcome. 

**Let's automate all the things! :sunglasses: :muscle:** 