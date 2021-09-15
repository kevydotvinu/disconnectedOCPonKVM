### What

#### Deploy OpenShift 4.x on KVM host using a script

### Why

#### Useful for reproducing support case scenario
* Creating a cluster with the below customization will be hassle-free. 
   * Disconnected cluster
   * Connected cluster with proxy
   * Provision nodes using PXE server
   * Add RHEL nodes

* The deployment completes considerably fast since we have created all the piece parts as ready-to-run scripts.
  * Nodes use KVM ready images and cli provisioning
  * Downloading and setting up the requiremnets are just a matter of running a script

#### The Quicklab cluster and RHEV infra will not be enough for complex scenario replication
* Using PXE server and proxy will not be possible
* Accessing boot menu or serial console are annoying

#### Useful for Hackathon / Testathon
* Save time from infra preparation
* All work can be done without leaving the terminal

#### It is simple bash so tweaks can be done
* Created the script steps with fuction in it so it is easy to remove the piece parts just by commenting it
* It is Vagrant kind of directory structure. All the related files and configurations are placed inside its own direcotry

#### RHCOS serial console access + BIOS in terminal
* Serial console can be accessible from terminal - Good for network related scenarios
* Boot menu can be accessible from terminal - No need to relay on GUI console which usually opens just after the max time to hit the TAB or 'e'.

#### Cluster access ( Web + CLI ) is also easy.
* That can be achieved by simple adding the below entries in the client machine's `/etc/hosts` file
```
<kvm-host-ip> api.ocp.example.local
<kvm-host-ip> oauth-openshift.apps.ocp.example.local
<kvm-host-ip> console-openshift-console.apps.ocp.example.local
```

### How
#### Architecture
![enter image description here](https://raw.githubusercontent.com/kevydotvinu/disconnectedOCPonKVM/main/.img/architecture.png)

#### Needs

* A virtual machine with pass-through host CPU enabled. The host resources must meet:
  * RAM:  120 GB
   * CPU:  20
   * DISK: 360 GB

* Example Pass-Through Host CPU configuration in RHV.

![enter image description here](https://raw.githubusercontent.com/kevydotvinu/disconnectedOCPonKVM/main/.img/passThroughHostCpu.png)
* Use RHEL 7 ISO for KVM host installation.

#### Get script
```
$ git clone https://github.com/kevydotvinu/disconnectOCPonKVM && cd disconnectOCPonKVM
```

#### Configure host
```
$ bash configureHost.sh
```
#### Download and prepare files
```
$ cd downloads && bash downloadFiles.sh '<VERSION>' && bash sshAndPullsecret.sh '<ACCESS_TOKEN>'
```
#### Create cluster
##### Disconnected + non-proxy
```
$ cd ../registry && bash createRegistry.sh && bash startRegistry.sh
$ cd ../cluster-files && bash install-config.sh -t disconnected -i non-proxy && bash createManifestsAndIgnitionConfig.sh
```
##### Connected + proxy
```
$ cd ../proxy && bash creatSquid.sh && startSquid.sh
$ cd ../cluster-files && bash install-config.sh -t connected -i proxy && bash createManifestsAndIgnitionConfig.sh
```
##### Connected + non-proxy
```
$ cd ../cluster-files && bash install-config.sh -t connected -i non-proxy && bash createManifestsAndIgnitionConfig.sh
```
#### Create nodes
##### Bootstrap node
```
$ cd ../bootstrap && bash bootstrap.sh
```
##### Master node
```
$ cd ../master/master0 && bash master.sh
$ cd ../master/master1 && bash master.sh
$ cd ../master/master2 && bash master.sh
```
##### Worker node
```
$ cd ../worker/worker0 && bash worker.sh
$ cd ../worker/worker1 && bash worker.sh
```
###### Create worker node from PXE server with NIC bonding
```
$ cd ../../pxe && bash createPXE.sh && bash startPXE.sh
$ cd ../worker/worker2 && bash worker.sh
```
###### Create and add RHEL8 worker node to the cluster
```
$ cd ../rhel8 && bash create rhel8
$ bash hosts.sh && ansible-playbook -i hosts /usr/share/ansible/openshift-ansible/playbooks/scaleup.yml
$ bash approve.sh
```
