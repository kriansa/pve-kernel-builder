# Proxmox custom Kernel compiler

> Unmaintained. Although this infrastructure allows one to use it to compile kernel easily using
> AWS, the purpose of this whole project was to serve as a workaround for a bug affecting HP Gen8
> Proliant Microserver, which I don't use anymore. Also, pve has upgraded the kernel and after 5.4
> the RMRR patch doesn't work anymore.

Fully automated kernel image builder with custom patches for `pve-kernels`.

It looks for new commits at the [pve-kernel repository][pve-kernel-repo] every day and initiate a
build process if necessary, then publish them to an APT repository on a S3 bucket of your choice.

Currently it's being used to compile kernel for a RMRR issue that HP Proliant Microserver Gen8 has
when passing through PCI devices.

## Context

HP Proliant Microserver Gen8 is a server that uses regions of the memory to communicate device
statuses for management purposes. That is relied upon RMRR (Reserved Memory Region Reporting).

Since Kernel 3.16, it's no longer possible to pass through a PCI device to a VM due to a change to
avoid possible conflicts on hardware by using this feature.

HP has provided an [official solution][hp-workaround] to disable RMRR on their platform, but it
doesn't work for most people - including me.

An alternative way of doing that is both proceeding with the solution provided by HP as well as to
remove the RMRR restriction from Kernel, leaving it as [just a warning message][patch].

Unfortunately, Kernel is updated very often and we couldn't just compile it once and forget.
Therefore, this project aims to provide a full automated build system for PVE kernels by using
AWS services.

A compilation procedure takes about 55 minutes and costs a little less than *USD $ 0.0812* (as of
Feb 2020).

## Dependencies

1. Docker, [Terraform](https://terraform.io) & [Terraform-auto](https://github.com/kriansa/devops-tools/)
2. An AWS, a Docker Repository such as Docker Hub or AWS ECR and a Terraform Cloud account.
3. A S3 bucket configured to serve APT files with S3 website.
   This bucket **must** be configured at the `.env` file
4. A S3 bucket configured to be used as an artifacts repository.
   This bucket **must** be named `kernel-builder-artifacts-<AWS_REGION>-<AWS_ACCOUNT_ID>`
5. A [GPG private key created][gpg-tutorial] and saved to the Artifacts S3 Bucket.
   This file **must** be named `gpg-private-key.asc`
 
## Setup

To start using this project, first ensure you have all the dependencies above. Then, let's setup
this at the server side, then at the client (your Proxmox instance).

### 1. Setup the project on the server

Once you satisfied all dependencies above, you will configure the `.env` file at the root folder of
the project. Ensure you have your AWS profile set correctly on your `~/.aws/credentials`.

Now, you must build the Docker image and publish to your repo. First, ensure you have a repository
setup on your Docker Repository service (such as Docker Hub). Then, run the following commands
at the root of the project:

```shell
$ make build-image publish-image
```

Once it's finished, you can deploy. A deploy means the infrastructure needed for the build service
to run will be prepared for builds, as well as a lambda function will be set to run daily. 

```shell
$ make deploy
```

After the deploy, the needed infrastructure to build the kernels will be on your AWS account, but no
Kernel is built yet. You will need to [trigger the build manually][#manually-running-a-build] for
the first time.

### 2. Setup your local APT repository

To get started using the compiled kernels from this project, you need to configure your Proxmox
instances to use your new repository to get the `pve-kernel-5.3` package. That can be done by
setting up the repository like that (remember to run all these commands as **root**):

1. Download the GPG public key from the repo:
   ```shell
   curl -o /etc/apt/trusted.gpg.d/custom-pve-repo.asc https://<YOUR_REPO_URL>/<REPO_S3_APT_PATH>/repo-gpg-key.asc
   ```
   
   PS: `REPO_S3_APT_PATH` is set at the `.env` file and its default value is `debian`.

2. Add the repository to the sources.list.d folder:
   ```shell
   echo "deb https://<YOUR_REPO_URL>/<REPO_S3_APT_PATH> buster kernel-normrr" > /etc/apt/sources.list.d/garajau-repo.list
   ```
   
3. Add a pin rule to make sure APT will always use the packages provided by your repository:
    ```shell
    cat <<EOF > /etc/apt/preferences.d/1-pin-pve-kernel
    Package: pve-kernel-5.3
    Pin: origin <YOUR_REPO_URL>
    Pin-Priority: 1001
    EOF
    ```
    
4. Now you can safely update your system:
   ```shell
   apt update && apt upgrade
   ```
    
## Debugging compilation

If the compilation does not succeed and you can't see files at your repo S3 bucket, then you can
check the logs on CloudWatch, under the `Kernel-Builder` log group.

## Building locally

If you just want to build it locally, then just run the following:

```shell
$ make build-env
$ build-kernel
```

This will make the .deb files locally available. If you wish to publish them to the S3 bucket, then:

```shell
$ setup-apt-repo && publish-to-s3
```

## Manually running a build

By default, a Lambda function will check for updates on the [pve-kernel repository][pve-kernel-repo]
daily. However, if you need to trigger the build process manually, you can just run:

```
$ make trigger-kernel-build
```

## License

Apache 2.0

[hp-workaround]: https://support.hpe.com/hpesc/public/docDisplay?docId=emr_na-c04781229
[patch]: patches/kernel/0099-iommu-bypass-intel-rmrr-restriction.patch
[gpg-tutorial]: https://github.com/kriansa/til/blob/master/security/gnupg.md
[pve-kernel-repo]: https://git.proxmox.com/?p=pve-kernel.git;a=summary
