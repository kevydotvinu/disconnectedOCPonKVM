#### What
→ Deploy OpenShift 4.x on KVM host using a script

### Why
→ Useful for reproducing support case scenario
→ In some cases Quicklab cluster and RHEV infra will not be enough for complex scenario replication
→ We can accomadate disconnected + more cluster scenario like proxy, pxe, etc
→ Useful for Hackathon
→ It is simple bash so tweaks can be done
→ RHCOS serial console access + BIOS in terminal

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
│   │  │         │ │         │ │         │ │         │ │         │ │         │  │   │  --> LB - Haproxy container
│   │  │ Bootstrap │  Master01 │  Master02 │  Master03 │  Worker01 │  Worker02  │   │  --> Web server
│   │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘  │   │  --> Registry
│   │                                                                    RHEL KVM   │  --> Proxy
│   └───────────────────────────────────────────────────────────────────────────┘   │  --> PXE
│                                                                                RHEV  RHVH
└───────────────────────────────────────────────────────────────────────────────────┘  --> Pass-Through Host CPU

#### Needs
→ A virtual machine with pass-through host CPU enabled. The host resources must meet:
   RAM:  120 GB
   CPU:  20
   DISK: 360 GB

→ See this [1] image.
  [1]: https://drive.google.com/file/d/1f3kb7bhFbvUzFE0WMsI4B3wa6jNNQK6j/view?usp=sharing

→ Use RHEL 7 ISO

#### How
→ Get script
   $ git clone https://github.com/kevydotvinu/disconnectOCPonKVM

→ Configure host
   $ bash configureHost.sh
   $ cd downloads && bash downloadFiles.sh '<VERSION>' && bash sshAndPullsecret.sh '<ACCESS_TOKEN>'
   $ cd ../registry && bash createRegistry.sh & startRegistry.sh
   $ cd ../cluster-files && bash install-config.sh && bash createManifestsAndIgnitionConfig.sh
   $ cd ../bootstrap && bash bootstrap.sh
