#### What

--> Deploy OpenShift 4.x on KVM host using a script

### Why

--> Useful for reproducing support case scenario

    [1] Creating a cluster with the below customization will be hassle-free.

        [a] Disconnected cluster
        [b] Connected cluster with proxy
        [c] Provision nodes using PXE server
        [d] Add RHEL nodes

    [2] The deployment completes considerably fast since we have created all the piece parts as ready-to-run scripts.

        [a] Nodes use KVM ready images and cli provisioning
        [b] Downloading and setting up the requiremnets are just a matter of running a script

--> In some cases Quicklab cluster and RHEV infra will not be enough for complex scenario replication

    [1] Using PXE server and proxy will not be possible
    [2] Accessing boot menu or serial console are annoying

--> Useful for Hackathon / Testathon

    [1] Save time from infra preparation
    [2] All work can be done without leaving the terminal

--> It is simple bash so tweaks can be done

    [1] Created the script steps with fuction in it so it is easy to remove the piece parts just by commenting it
    [2] It is Vagrant kind of directory structure. All the related files and configurations are placed inside its own direcotry

--> RHCOS serial console access + BIOS in terminal

    [1] Serial console can be accessible from terminal - Good for network related scenarios
    [2] Boot menu can be accessible from terminal - No need to relay on GUI console which usually opens just after the max time to hit the TAB or 'e'.

--> Cluster access ( Web + CLI ) is also easy.

    [1] That can be achieved by simple adding the below entries in the client machine's `/etc/hosts` file
        <kvm-host-ip> api.ocp.example.local
        <kvm-host-ip> oauth-openshift.apps.ocp.example.local
        <kvm-host-ip> console-openshift-console.apps.ocp.example.local

#### Architecture

   ┌───────────────────────────────────────────────────────────────────────────────────┐
   │                                                                                   │
   │   ┌───────────────────────────────────────────────────────────────────────────┐   │
   │   │                                                                           │   │
   │   │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │   │
   │   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │
   │   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │
   │   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │
   │   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │
   │   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │
   │   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │  RHEL HOST (Big VM)
   │   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │  --> Hypervisor - KVM
   │   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │  --> DNS - NetworkManger + dnsmasq
   │   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │  --> LB - haproxy container
   │   │  │ Bootstrap │  Master01 │  Master02 │  Master03 │  Worker01 │  Worker02  │   │  --> Web server - screen + python module
   │   │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘  │   │  --> Container image registry - registry:2 container
   │   │                                                                    RHEL KVM   │  --> Proxy - squid proxy container
   │   └───────────────────────────────────────────────────────────────────────────┘   │  --> PXE - dnsmasq proxy pxe container
   │                                                                                RHEV  RHVH
   └───────────────────────────────────────────────────────────────────────────────────┘  --> Pass-Through Host CPU

#### Needs

--> A virtual machine with pass-through host CPU enabled. The host resources must meet:

    RAM:  120 GB
    CPU:  20
    DISK: 360 GB

--> See this [1] image.

    [1]: https://drive.google.com/file/d/1f3kb7bhFbvUzFE0WMsI4B3wa6jNNQK6j/view?usp=sharing

--> Use RHEL 7 ISO

#### How

--> Get script

    $ git clone https://github.com/kevydotvinu/disconnectOCPonKVM && cd disconnectOCPonKVM

--> Configure host

    $ bash configureHost.sh
    $ cd downloads && bash downloadFiles.sh '<VERSION>' && bash sshAndPullsecret.sh '<ACCESS_TOKEN>'
    $ cd ../registry && bash createRegistry.sh && bash startRegistry.sh
    $ cd ../cluster-files && bash install-config.sh && bash createManifestsAndIgnitionConfig.sh
    $ cd ../bootstrap && bash bootstrap.sh
