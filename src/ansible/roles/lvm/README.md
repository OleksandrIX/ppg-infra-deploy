# lvm

Ansible role for managing LVM storage on PostgreSQL cluster nodes. The role supports initial provisioning of a volume group and logical volume or extending an existing setup with additional disks.

## Requirements

- Debian-based OS
- Target disks must be available to the host
- Ansible collections `community.general` and `ansible.posix`

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `lvm_state` | `create` | Operation mode: `create` or `extend` |
| `pv_devices` | `["/dev/sdb"]` | Block devices to partition and use as physical volumes |
| `vg_name` | `vg` | Volume group name |
| `lv_name` | `lv` | Logical volume name |
| `fs_type` | `xfs` | Filesystem type for the logical volume |
| `mount_path` | `/mnt/data` | Mount point for the filesystem |

## Included Task Files

| File | Description |
|---|---|
| `prepare.yml` | Installs LVM and filesystem tooling |
| `create.yml` | Creates partitions, VG, LV, filesystem, and mount |
| `extend.yml` | Adds disks to the VG and extends the LV/filesystem |

## Example Playbook

```yaml
- name: "Create LVM storage"
  hosts: "db_cluster"
  become: true
  vars:
    lvm_state: "create"
    pv_devices:
      - "/dev/sdb"
    vg_name: "vg_pgdata"
    lv_name: "lv_pgdata"
    fs_type: "xfs"
    mount_path: "/var/lib/postgresql"
  roles:
    - role: lvm
```

```yaml
- name: "Extend LVM storage"
  hosts: "db_cluster"
  become: true
  vars:
    lvm_state: "extend"
    pv_devices:
      - "/dev/sdb"
      - "/dev/sdc"
    vg_name: "vg_pgdata"
    lv_name: "lv_pgdata"
    fs_type: "xfs"
    mount_path: "/var/lib/postgresql"
  roles:
    - role: lvm
```

## Notes

- In `create` mode the role creates a single GPT partition with the LVM flag on every device in `pv_devices`.
- The logical volume is sized to `100%VG` during creation.
- In `extend` mode the logical volume grows by `+100%FREE` and the filesystem is resized automatically.
- The resulting mapped device path follows `/dev/mapper/<vg_name>-<lv_name>`.
