# Linux Scripts


## Requirements

It is assumed these are running on a Linux/MacOSX computer.  (Bash for Windows)

- Azure 2.0 CLI
- JQ

> Detailed Instructions can be found in the tutorial
[Complete Linux Environment](https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-create-cli-complete#create-a-virtual-network-and-subnet)

### Login and Set Subscription

``` bash
shell>$ az login
shell>$ az set subscription --subscription <your_subscription>
```

### Create a Virtual Machine

``` bash
shell>$ ./create.sh <your_vm_name>
```

### Connect to Server

``` bash
shell>$ ./connect.sh <your_vm_name>
```

### Optional: Load Balancer

To complete the load balancer setup you manually have to add the BackEnd Pool and Load Balancer Rule


### Optional: Create Docker Certs

``` bash
shell>$ ./certs.sh <your_vm_name>
```
