# Creates Ansible inventory file

function CREATE_INVENTORY {
cat << EOF > hosts
[all:vars]
ansible_user=user
ansible_become=True 
ansible_ssh_private_key_file=$(dirname $(pwd))/downloads/id_ed25519

openshift_kubeconfig_path=$(dirname $(pwd))/cluster-files/auth/kubeconfig

[new_workers] 
192.168.122.98
EOF
}

CREATE_INVENTORY
