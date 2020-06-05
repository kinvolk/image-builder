# Provisioning Flatcar with Packer + Ansible

- [Provisioning Flatcar with Packer + Ansible](#provisioning-flatcar-with-packer--ansible)
  - [Overview](#overview)
  - [Usage](#usage)
  - [Notes](#notes)
  - [TODOs](#todos)

## Overview

This is a Cluster API image builder for [Flatcar Container Linux](https://www.flatcar-linux.org).

On the Packer side it includes `packer/qemu/flatcar.json` and `packer/qemu/packer.json`.
In `packer/config/` it also includes some other JSON files with configuration for
ansible and packages installed with Ansible.

On the Ansible side there's some preliminary playbook in `ansible/`.

## Prerequisites

* [packer](https://packer.io/) v1.5 or newer
* [ansible](https://github.com/ansible/ansible/releases) v2.9 or newer
* (optional) libvirtd, libvirt-client, vagrant, and virt-manager (for testing)

### Recommendation

Before running `packer build` command, please make sure the following:

* Your system should not be under heavy CPU load. It can prevent Packer's VNC commands from being passed in.
* During the VNC phase of Packer build, please do not open another VNC viewer to the same port. That could also prevent VNC commands from being passed in.

## Usage

Provisioning and `kubeadm` initialisation is automated; start a new build with
```shell
./hack/image-build-flatcar.sh [<channel>] [<release-version>]
```

The build script will default to the latest release of the `stable` channel.

After provisioning concluded the script will ask you to export flatcar channel
and release version environment variables:
```shell
  export FLATCAR_CHANNEL='<channel>'
  export FLATCAR_VERSION='<version>'
  export VAGRANT_VAGRANTFILE='<vagrantfile>'"
```

You're now set up to interact with your cluster via `vagrant ssh`. Try e.g.

```shell
$ vagrant ssh 'kubectl cluster-info'
Kubernetes master is running at https://10.0.2.15:6443
KubeDNS is running at https://10.0.2.15:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

## Notes

* It needs to disable `gather_facts` in `images/capi/ansible/node.yml`, because it is not possible to run python before running setup tasks. Note that python is not installed by default in Flatcar.
* To make `ansible_env.SUDO_USER` work with `gather_facts` disabled, `setup: filter=ansible_env` is needed in `images/capi/ansible/roles/sysprep/tasks/main.yml`.
* `images/capi/ansible/roles/setup/tasks/bootstrap-flatcar.yml` installs python under `/opt`.
* `images/capi/ansible/roles/kubernetes/tasks/url-flatcar.yml` installs artificts of Kubernetes and CNI under `/opt` and `/etc`, mainly because `/usr` is read-only in Flatcar.
* `images/capi/ansible/roles/sysprep/tasks/main.yml` sets hostname with `use: systemd` in case of Flatcar. It is a workaround to avoid hostname detection errors when running ansible in Flatcar. We [fixed the issue](https://github.com/ansible/ansible/pull/69627) in upstream Ansible, but it is not included in any Ansible release yet.
* It unpacks only parts of containerd binaries, since Flatcar already has its own built-in containerd.
* To make containerd work correctly, we install Flatcar-specific config files for containerd, so it listens on its containerd socket `/run/docker/libcontainerd/docker-containerd.sock`.
* Since Flatcar has its own containerd socket, we need to also specify the socket name when running commands like `kubeadm config images pull`, `/opt/bin/ctr images import` as well as in `/etc/crictl.yaml`.
* We do not delete `/etc/kubeadm.yml` for Flatcar, because later steps running `kubeadm init` require the config to be in place.

## TODOs

* Make sure it works for other platforms than qemu
* Get Makefile support multiple Flatcar channels and versions
