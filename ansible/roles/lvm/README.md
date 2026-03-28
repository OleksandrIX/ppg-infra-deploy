# lvm

Ansible role for managing LVM (Logical Volume Manager) storage on PostgreSQL cluster nodes. Supports two operations: creating a new LVM setup from scratch or extending an existing Volume Group with additional disks.

## Requirements

- Debian-based OS (uses `apt` for package installation)
- Target disks must be available and unpartitioned (for `create` mode)
- Ansible collections:
  - `community.general`
  - `ansible.posix`

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `lvm_state` | `create` | Operation mode: `create` — initial setup, `extend` — add disk(s) to existing VG |
| `pv_devices` | `["/dev/sdb"]` | List of block devices to use as Physical Volumes |
| `vg_name` | `vg` | Volume Group name |
| `lv_name` | `lv` | Logical Volume name |
| `fs_type` | `xfs` | Filesystem type to format the Logical Volume with |
| `mount_path` | `/mnt/data` | Path where the Logical Volume will be mounted |

## Tasks

| File | Description |
|---|---|
| `prepare.yml` | Installs required packages: `lvm2`, `xfsprogs`, `parted`, `acl`, `curl`, `jq`, `vim` |
| `create.yml` | Partitions disks, creates VG/LV, formats filesystem, mounts and persists via fstab |
| `extend.yml` | Partitions new disks, extends existing VG, resizes LV to use all free space |

## Example Playbook

```yaml
- name: "LVM setup for PostgreSQL cluster nodes"
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

### Extending an existing VG with additional disks

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

- In `create` mode the LV is sized at `100%VG` — all available space in the VG.
- In `extend` mode the LV is resized with `+100%FREE` and the filesystem is automatically grown.
- All devices in `pv_devices` are partitioned with a single GPT partition flagged for LVM before being added to the VG.
- The resulting device path follows the pattern `/dev/mapper/<vg_name>-<lv_name>`.
