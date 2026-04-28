# inventory

Scripts to audit infrastructure inventory consistency.

- `pull-hosts-ansible.sh` — compares running Proxmox VMs/CTs against an Ansible hosts file, reporting mismatches in both directions
- `list-rudder-servers.sh` — cross-checks Rudder-managed servers against Proxmox clusters
- `backup.sh` — backup helper
