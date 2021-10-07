### TL;DR
#### A script-based deployment of OpenShift Container Platform on a restricted network
##### Requirements
* RHEL 7 virtual machine with KVM and [other packages](#install-packages) installed.
* OCM API Token from [here](https://console.redhat.com/openshift/token/).
##### Deployment
```
$ git clone https://github.com/kevydotvinu/disconnectedocponkvm
$ cd disconnectedocponkvm
$ sed -i 's/RELEASE=.*/RELEASE=4.7.7/' env
$ sed -i 's/OCM_TOKEN=.*/OCM_TOKEN=<your-token>/' env
$ cd cluster-files
$ bash deploy.sh
```
> Note: If anything breaks in the middle, fix the issue and re-run the `bash deploy.sh` command.
##### Demo
[![asciicast](https://asciinema.org/a/iFc4KIRQI8DE79i9eVhcbdl2e.svg)](https://asciinema.org/a/iFc4KIRQI8DE79i9eVhcbdl2e)
> Note: Trimmed the terminal session from where it waits long.

### What

#### Deploy OpenShift 4.x on KVM host using a script

### Why

#### Useful for reproducing support case scenario
* Creating a cluster with the below customization will be hassle-free
   * Disconnected cluster.
   * Connected cluster with proxy.
   * Provision nodes using PXE server.
   * Add RHEL nodes.

* The deployment completes considerably fast since we have created all the piece parts as ready-to-run scripts.
  * Nodes use KVM ready images and cli provisioning.
  * Downloading and setting up the requiremnets are just a matter of running a script.

#### The Quicklab cluster and RHEV infra will not be enough for complex scenario replication
* Using PXE server and proxy will not be easy.
* Accessing boot menu or serial console are annoying.

#### Useful for Hackathon / Testathon
* Save time from infra preparation.
* All work can be done without leaving the terminal.

#### It is bash script and tweaks can be done easily
* Created the script steps with fuction in it so it is easy to remove the piece parts just by commenting it.
* It is Vagrant kind of directory structure. All the related files and configurations are placed inside its own direcotry.

#### RHCOS serial console access + BIOS in terminal
* Serial console can be accessible from terminal - Good for network related scenarios.
* Boot menu can be accessible from terminal - No need to relay on GUI console which usually opens just after the max time to hit the TAB or 'e'.

### How
#### Architecture
![enter image description here](https://raw.githubusercontent.com/kevydotvinu/disconnectedOCPonKVM/main/.img/architecture.png)

#### Prerequisites

* A virtual machine with pass-through host CPU enabled. The host resources must meet:

| CPU | RAM | Storage |
|-----|-----|---------|
| 30 | 120 GB | 300 GB |

* Nested virtualization - The below is the pass-through host CPU configuration in RHV environment

![enter image description here](https://raw.githubusercontent.com/kevydotvinu/disconnectedOCPonKVM/main/.img/passThroughHostCpu.png)

* RHEL 7 operating system
  * For additional disk, make filesystem using `mkfs -t xfs -n ftype=1 /dev/<disk>` command. For overlay fs, `ftype=1` is a requirement.

#### Get script
```
$ git clone https://github.com/kevydotvinu/disconnectOCPonKVM && \
  cd disconnectOCPonKVM
```

#### Configure host
##### Install packages
```
$ subscription-manager register
$ subscription-manager repos --enable="rhel-7-server-rpms" \
                             --enable="rhel-7-server-extras-rpms" \
                             --enable="rhel-7-server-ansible-2.9-rpms" \
                             --enable="rhel-7-server-ose-4.7-rpms"
$ yum -y update
$ yum groupinstall -y virtualization-client virtualization-platform virtualization-tools
$ yum install -y screen podman httpd-tools jq git openshift-ansible
```
##### Configure dependent services
```
$ bash configureHost.sh -s all
```
#### Download and prepare files
```
$ sed -i 's/RELEASE=.*/RELEASE=4.7.7/' env
$ cd downloads && \
  bash downloadFiles.sh && \
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
  bash master0.sh
$ cd ../master/master1 && \
  bash master1.sh
$ cd ../master/master2 && \
  bash master2.sh
```
##### Worker node
```
$ cd ../worker/worker0 && \
  bash worker0.sh
$ cd ../worker/worker1 && \
  bash worker1.sh
```
###### Create worker node from PXE server with NIC bonding
```
$ cd ../../pxe && \
  bash createPXE.sh && \
  bash startPXE.sh
$ cd ../worker/worker2 && \
  bash worker2.sh
```
###### Create and add RHEL8 worker node to the cluster
```
$ cd ../rhel8 && \
  bash create rhel8
$ bash hosts.sh && \
  ansible-playbook -i hosts /usr/share/ansible/openshift-ansible/playbooks/scaleup.yml
$ bash approve.sh
```
#### Upgrade cluster
##### Set latest release
```
$ sed -i 's/RELEASE=.*/RELEASE=4.7.7/' env
```
##### Mirror OpenShift image repository
```
$ cd registry && \
  bash mirror.sh
```
##### Initiate upgrade
```
$ source ./env
$ TOIMAGE=$(oc adm release info ${PULLSECRET} mirror.ocp.example.local:5000/ocp4/openshift4:${RELEASE}-x86_64 | grep "Pull From" | cut -d" " -f3)
$ oc adm upgrade --to-image=${TOIMAGE} --allow-explicit-upgrade
```
#### Tips and Tricks
##### Enable internet for guest VMs
```
$ bash configureHost.sh -s vms-internet
```
##### Import image for disconnected cluster
```
$ cd downloads
$ skopeo copy --authfile pull-secret.json docker://quay.io/openshift/origin-must-gather \
                                          docker-archive:$(pwd)/must-gather.tar
$ ssh core@bootstrap
$ cd /tmp
$ scp <user>@<IP>:/path/must-gather.tar .
$ skopeo copy docker-archive:$(pwd)/must-gather.tar containers-storage:quay.io/openshift/origin-must-gather
$ podman images | grep must-gather
```
```
$ cd downloads
$ skopeo copy --authfile pull-secret.json docker://registry.redhat.io/rhel8/support-tools \
                                          docker://mirror.ocp.example.local:5000/rhel8/support-tools
$ cat << EOF > image-policy-2.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: image-policy-2
spec:
  repositoryDigestMirrors:
  - mirrors:
    - mirror.ocp.example.local:5000/rhel8/support-tools
    source: registry.redhat.io/rhel8/support-tools
EOF
$ oc create -f image-policy-2.yaml
$ watch oc get mcp
```
##### Create a user with password authentication (username: foo, password: bar)
If we are working with nework related problem, TTY conosle login is possible with this using VM's serial console.
```
$ cd cluster-files
$ perl -e 'print crypt("bar","\$6\$SALT\$") . "\n"'
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
##### Cluster access from output of the KVM host
Add the below entries in the machine where the cluster does access.
```
<kvm-host-ip> api.ocp.example.local
<kvm-host-ip> oauth-openshift.apps.ocp.example.local
<kvm-host-ip> console-openshift-console.apps.ocp.example.local
```
##### Check upgrade path
```
cd registry &&
bash checkUpgradePath.sh
```
