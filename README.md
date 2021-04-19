# PHP-Nginx-Kubernetes
Devops Task Assignment - 
This project feature a web-page application using php-module which is been running on EKS cluster of which the infrastructure is provisioned with Terraform.

<img width="630" alt="Capture" src="https://user-images.githubusercontent.com/33144027/115149929-dd5dbd00-a083-11eb-954f-e8fed65c7df4.PNG">

As you can see in the diagram, the infrastructure consists of 3 web servers running in a EKS cluster which is publicly available using a Application load balancer and the webservers which includes php-nginx are attached to a database server i.e. postgresql and the whole is running on AWS services which is provisioned using terraform.

**Clone the below terraform repository**
```
$ git clone https://github.com/SubhakarKotta/aws-eks-rds-terraform.git
$ cd PHP-Nginx-Kubernetes/terraform
```

<h1> Creating AWS VPC and EKS cluster </h1>

**Provide AWS Credentials**

```
$ aws configure:
$............... AWS Access Key ID [None]:
$............... AWS Secret Access Key [None]:
$............... Default region name [None]:
$............... Default output format [None]:
```

Initialize and pull terraform cloud specific dependencies:
```
$ terraform init
```
View terraform plan:
```
$ terraform plan
```
Apply terraform plan:
```
$ terraform apply
```

Terraform modules will create
```
-   VPC
-   Subnets
-   Routes
-   IAM Roles for master and nodes
-   Security Groups "Firewall" to allow master and nodes to communicate
-   EKS cluster
-   Autoscaling Group will create nodes to be added to the cluster
-   Security group for RDS which allow access from Webservers only
-   RDS with PostgreSQL DB instance
Note: Keep a note of the RDS endpoint generated which will be needed while creating service to access RDS instance from Webservers.
```

A file `kubeconfig_my-cluster` is available in the directory which is the kubeconfig for the newly created cluster.

Export the KUBECONFIG variable to the above kubeconfig file to access the cluster.<br>
```
$ export KUBECONFIG="${PWD}/kubeconfig_my-cluster"`
````
You can verify the kubernetes cluster by using following commands -
```
$ kubectl get nodes
$ kubectl get pods --all-namespaces
```

Now, we need to deploy php-nginx application for our Webservers to run.
```
$ cd kubernetes
```

There is an config.yaml file present which creates a config map which consists of nginx.conf configurations needed for running our webpage on nginx.</br>
```
$ kubectl apply -f config.yaml
$ kubectl get configmap
  NAME           DATA   AGE
  nginx-config   1      4m6s
```
We'll now deploy our static webpage application which consists of two images my-php-app:2.0.0 and nginx.</br>
```
$ kubectl apply -f nginx-deployment.yaml
$ kubectl get deployments
  NAME               READY   UP-TO-DATE   AVAILABLE   AGE
  nginx-deployment   3/3     3            3           59s
```
For the Postgresql RDS instance to be accessible through our webservers running in a EKS cluster, we create a external service called `postgresql-service` which is exposed through the endpoint generated when the instance was launched by terraform.</br>
`my-cluster.cijsdqmilarx.us-west-2.rds.amazonaws.com` </br>

We create the External service by executing the following - </br>
```
$ kubectl apply -f postgresql-service.yaml
  NAME                 TYPE           CLUSTER-IP   EXTERNAL-IP                                           PORT(S)   AGE
  postgresql-service   ExternalName   <none>       my-cluster.cijsdqmilarx.us-west-2.rds.amazonaws.com   <none>    34m
```
We can verify the conncetivity using the following commands: </br>
```
$ kubectl run -i --tty --rm debug --image=busybox:1.28.0 --restart=Never -- nslookup postgresql-service.default
  Server:    10.100.0.10
  Address 1: 10.100.0.10 kube-dns.kube-system.svc.cluster.local

  Name:      postgresql-service.default
  Address 1: 172.16.94.248 ip-172-16-94-248.us-west-2.compute.internal
```


We need to expose this deployment, for this we'll create our Load Balancer service to expose our Deployment.
```
$ kubectl apply -f nginx-php-service.yaml

  NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)      
  nginx-php-service    LoadBalancer   10.100.178.56   a74275af7beb543d898f9a98013c cf0b-778083184.us-west-2.elb.amazonaws.com   80:32587/TCP  
```


Now, we are defining a Kubernetes Ingress manifest  that routes all the traffic from path '/' to the Pods targeted by the `nginx-php-service`  Load BalancerService. </br>
For this, we need a ALB ingress controller to be deployed in out cluster. 
Since the Ingress controller runs as Pod in one of your Nodes, all the Nodes should have permissions to describe, modify, etc. the Application Load Balancer. For this, we are defining a iam role in `iam-policy.json` file.
Now, we can install the ALB ingress controller through Helm. Ensure that Helm is installed on your kubernetes cluster. </br>
`$ helm version` </br>

Execute the following commands to install the ALB ingress controller. </br>
`$ helm repo add eks https://aws.github.io/eks-charts.` </br>
`$ helm install aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=my-cluster -n kube-system'` </br>

Create an ingess manifest for our load balancer using the following command: </br>
`$ kubectl apply -f ingress.yaml` </br>
```
Name:             nginx-php-kubernetes
Namespace:        default
Address:          k8s-default-nginxphp-11a7134498-183686945.us-west-2.elb.amazonaws.com
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host  Path  Backends
  ----  ----  --------
  *
        /   nginx-php-service:80 (<none>)
```

We can access our webserver through the endpoint generated: </br>
```
$ curl k8s-default-nginxphp-11a7134498-183686945.us-west-2.elb.amazonaws.com
  <!DOCTYPE html>
<html>
  <head>
    <title>My Static Website</title>
  </head>
  <body>
    <h1>Hello World</h1>
    <p>
      Up and Available!!
    </p>
  </body>
</html>
```
You can connect through the browser using the endpoint - </br>
`http://k8s-default-nginxphp-11a7134498-183686945.us-west-2.elb.amazonaws.com`



























