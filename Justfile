
invt := "apealive"
book := invt
user := "epcim"
args := ""
target :="physical:cmp5-acr"

# settings
set export := true
set dotenv-load := true
set positional-arguments

default:
  @just --list

# install prereq
install:
  brew install ansible jq yq age

VAULT_PASS := env("VAULT_PASS", "$(gopass -o me/$invt/ansible-infra-vars)")

@deploy invt=invt book=book target=target: 
   echo {{VAULT_PASS}} | ansible-playbook -i inventory-{{invt}} play-{{book}}.yml -l {{target}} -u {{user}} --vault-password-file /dev/stdin {{args}}
