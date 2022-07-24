
# SRE-Ansible playbooks

Playbooks to bootstrap infrastructure for k8s.

Nodes:
- foundation, an boostrap node (can be local host)
- compute nodes (intel, arm)

## Setup

```sh
export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"
brew install coreutils
brew install binutils
brew install binutils
brew install diffutils
brew install findutils
brew install gawk
brew install grep
brew install gnu-tar
brew install gnu-sed
brew install gnu-which
brew install direnv gpg sops jq age

pipenv install -d --skip-lock
pipenv shell

# unseal secrets
gpg -d files/ops_id_ed25519.asc
gpg -d .private_vp.asc
gpg -d .${ENV}.age.asc

direnv allow .
```

Initially create secrets:
```
ssh-kegen -t ed25519 -f files/ops_id_ed25519
gpg -a -r epcim@apealive.net -e files/ops_id_ed25519
```

### AGE setup:

```sh
age-keygen -o .${ENV}.age

gpg -a -r epcim@apealive.net -e .${ENV}.age
git add -f .${ENV}.age.asc
```

### SOPS setup:

```sh
# configure AGE public key in .sops.yaml
vim .sops.yaml
```

## Usage

Doc:
- https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html


```sh
# to prepare foundation node
ansible-playbook bootstrap.yml -i hosts --check -vv

# to deploy nodes
ansible-playbook -i inventory-apealive play-apealive.yml --ask-become-pass -l default:ape1 -u pmichalec
# or
ansible-lint -i play-apealive.yml
ansible-playbook -i inventory-apealive play-apealive.yml 


# review
ansible-playbook -i inventory-apealive play-apealive.yml  --syntax-check
ansible-playbook -i inventory-apealive play-apealive.yml  --check -vv
```

Common tasks:

```
--extra-vars "aide_update_database=true hardening_disable_coredumps=false allow_node_restart=false"
```

Remote cmd execution

```
ansible prod -i inventory-apealive -m command -a "uname -r"
ansible prod -i inventory-apealive -b -B 1 -P 0 -m shell -a "sleep 5 && reboot" -l ip-172-16-177-177.us-east-2.compute.internal
```

Check running:
```
ansible-playbook -i inventory-apealive tasks/ping.yaml
```

Collect files:
```
ansible-playbook -i inventory-test tasks/coredumps.yaml --tags list
ansible-playbook -i inventory-test -e coredump_pattern=envoy tasks/coredumps.yaml --tags collect -l cmp1-nuc11

ansible-playbook -i inventory-test tasks/coredumps-kcd.yaml --tags list -e coredump_pattern="2022-01"
ansible-playbook -i inventory-test -e coredump_pattern=fluentbit tasks/coredumps-kcd.yaml --tags collect -l kube

find ./fetched
```

OS Upgrade:

```
ansible-playbook -i inventory-apealive tasks/ping.yaml
ansible-playbook -i inventory-apealive play-apealive.yml -e batch_size=5 -l kube --extra-vars "allow_node_restart=false" --tags upgrade -v
ansible-playbook -i inventory-apealive -e batch_size=1 -e allow_node_restart=true tasks/restart.yaml

# review
ansible prod-cle -i inventory-apealive -l cle -m command -a "uname -a" | grep Linux
ansible prod-cle -i inventory-apealive -l cle -m command -a "uptime"
ansible prod-cle -i inventory-apealive -l cle -m command -a 'yum list installed -v |grep kernel' -v |egrep '(compute|4\.)'
```


