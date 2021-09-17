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
   * RAM: **120 GB**
   * CPU: **30**
   * DISK: **360 GB**

* Example Pass-Through Host CPU configuration in RHV.

![enter image description here](https://raw.githubusercontent.com/kevydotvinu/disconnectedOCPonKVM/main/.img/passThroughHostCpu.png)
* Use RHEL 7 ISO for KVM host installation.

#### Get script
```
$ git clone https://github.com/kevydotvinu/disconnectOCPonKVM && \
  cd disconnectOCPonKVM
```

#### Configure host
```
$ bash configureHost.sh
```
#### Download and prepare files
```
$ sed -i 's/RELEASE=.*/RELEASE=4.8.2/' env
$ cd downloads && \
  bash downloadFiles.sh '<VERSION>' && \
  bash sshAndPullsecret.sh '<ACCESS_TOKEN>'
```
#### Create cluster
##### Disconnected + non-proxy
```
$ cd ../registry && \
  bash createRegistry.sh && \
  bash startRegistry.sh
$ cd ../cluster-files && \
  bash install-config.sh -t disconnected -i non-proxy && \
  bash createManifestsAndIgnitionConfig.sh
```
##### Connected + proxy
```
$ cd ../proxy && \
  bash creatSquid.sh && \
  bash startSquid.sh
$ cd ../cluster-files && \
  bash install-config.sh -t connected -i proxy && \
  bash createManifestsAndIgnitionConfig.sh
```
##### Connected + non-proxy
```
$ cd ../cluster-files && \
  bash install-config.sh -t connected -i non-proxy && \
  bash createManifestsAndIgnitionConfig.sh
```
#### Single node + proxy
```
$ cd ../cluster-files && \
  bash install-config.sh -t singlenode -i proxy && \
  bash createManifestsAndIgnitionConfig.sh
```
##### Operators adjustment for single node deployment (Run after the control plane is up)
```
$ bash sncPatch.sh
```
#### Single node + non-proxy
```
$ cd ../cluster-files && \
  bash install-config.sh -t singlenode -i non-proxy && \
  bash createManifestsAndIgnitionConfig.sh
```
##### Operators adjustment for single node deployment (Run after the control plane is up)
```
$ bash sncPatch.sh
```
#### Create nodes
##### Bootstrap node
```
$ cd ../bootstrap && \
  bash bootstrap.sh
```
##### Master node
```
$ cd ../master/master0 && \
  bash master.sh
$ cd ../master/master1 && \
  bash master.sh
$ cd ../master/master2 && \
  bash master.sh
```
##### Worker node
```
$ cd ../worker/worker0 && \
  bash worker.sh
$ cd ../worker/worker1 && \
  bash worker.sh
```
###### Create worker node from PXE server with NIC bonding
```
$ cd ../../pxe && \
  bash createPXE.sh && \
  bash startPXE.sh
$ cd ../worker/worker2 && \
  bash worker.sh
```
###### Create and add RHEL8 worker node to the cluster
```
$ cd ../rhel8 && \
  bash create rhel8
$ bash hosts.sh && \
  ansible-playbook -i hosts /usr/share/ansible/openshift-ansible/playbooks/scaleup.yml
$ bash approve.sh
```
#### Tips and Tricks
##### Directory structure
```
.
├── bootstrap
│   ├── bootstrap.sh
│   └── connect.sh
├── cluster-files
│   ├── connect.sh
│   ├── createManifestsAndIgnitionConfig.sh
│   └── install-config.sh
├── configureHost.sh
├── downloads
│   ├── downloadFiles.sh
│   └── sshAndPullsecret.sh
├── env
├── haproxy
│   ├── createHaproxy.sh
│   ├── Dockerfile
│   ├── haproxy.cfg
│   ├── startHaproxy.sh
│   └── stopHaproxy.sh
├── LICENSE
├── master
│   ├── master0
│   │   ├── connect.sh
│   │   └── master0.sh
│   ├── master1
│   │   ├── connect.sh
│   │   └── master1.sh
│   └── master2
│       ├── connect.sh
│       └── master2.sh
├── proxy
│   ├── createSquid.sh
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── startSquid.sh
│   └── stopSquid.sh
├── pxe
│   ├── boot.ipxe
│   ├── createPXE.sh
│   ├── dnsmasq.conf.dhcpproxy
│   ├── Dockerfile
│   ├── startPXE.sh
│   └── stopPXE.sh
├── README.md
├── registry
│   ├── createRegistry.sh
│   ├── mirror.sh
│   ├── startRegistry.sh
│   └── stopRegistry.sh
├── rhel8
│   ├── approve.sh
│   ├── connect.sh
│   ├── create.sh
│   └── hosts.sh
├── setup.md
├── snc
│   ├── bootstrap.sh
│   ├── connectBootstrap.sh
│   ├── connectMaster.sh
│   ├── master0.sh
│   └── sncPatch.sh
└── worker
    ├── worker0
    │   ├── approve.sh
    │   ├── connect.sh
    │   └── worker0.sh
    ├── worker1
    │   ├── approve.sh
    │   ├── connect.sh
    │   └── worker1.sh
    └── worker2
        ├── approve.sh
        ├── connect.sh
        └── worker2.sh

17 directories, 56 files
```
##### Enable internet for VMs (MASQUERADE)
```
iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE
```
##### Import image for disconnected cluster
```
$ skopeo login --authfile pull-secret.json quay.io && \
  skopeo copy docker://quay.io/openshift/origin-must-gather docker-archive:$(pwd)/must-gather.tar
$ ssh core@bootstrap
$ cd /tmp
$ scp <user>@<IP>:/path/must-gather.tar .
$ skopeo copy docker-archive:$(pwd)/must-gather.tar containers-storage:quay.io/openshift/origin-must-gather
$ podman images | grep must-gather
```
##### Create a user with password authentication (username: foo, password: bar)
If we are working with nework related problem, TTY conosle login is possible with this using VM's serial console.
```
$ cat << EOF > passwd.bu
variant: fcos
version: 1.3.0
passwd:
  users:
    - name: foo
      password_hash: $6$SALT$HsCT89cn4dek.8MuFh5ZRlC5A5ofnlqB6FxLX7v/lssLC7/6rutMtCvZxsixpkpLn9GXr1iiLuQyB8DpI2lyz/
storage:
  files:
    - path: /etc/ssh/sshd_config.d/20-enable-passwords.conf
      mode: 0644
      contents:
        inline: |
          PasswordAuthentication yes
EOF
$ podman run --interactive --rm quay.io/coreos/butane:release --pretty --strict < passwd.bu > passwd.ign
$ [ -f bootstrap.ign.bkp ] || cp bootstrap.ign bootstrap.ign.bkp
$ jq -c --argjson var "$(jq .passwd.users passwd.ign)" '.passwd.users += $var' bootstrap.ign.bkp > bootstrap.ign.1
$ jq -c --argjson var "$(jq .storage.files passwd.ign)" '.storage.files += $var' bootstrap.ign.1 > bootstrap.ign
$ rm -vf bootstrap.ign.1
```
