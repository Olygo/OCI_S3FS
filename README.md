# S3FS

s3fs allows Linux, macOS, and FreeBSD to mount an OCI bucket via [FUSE(Filesystem in Userspace)](https://github.com/libfuse/libfuse).  
s3fs makes you operate files and directories in S3 bucket like a local file system.  
s3fs preserves the native object format for files, allowing use of other tools like [OCI CLI](https://github.com/oracle/oci-cli).  

***This script is designed to simplify the process of mounting an OCI Object Storage bucket using the s3fs-fuse. It prompts the user for necessary information, installs required dependencies, and sets up the mounting configuration.***

## Script Prerequisites

Before using this script, ensure that you have the following prerequisites:

- [An OCI Object Storage bucket](https://docs.public.oneportal.content.oci.oraclecloud.com/en-us/iaas/Content/Object/Tasks/managingbuckets_topic-To_create_a_bucket.htm)
	- S3FS works only with bucket name using lowecases 

- [OCI credentials](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2)
	- Customer Secret Key ID and Customer Secret Key Secret

- [OCI Storage namespace](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/understandingnamespaces.htm)
	- Namespace is displayed in the bucket details 

- [OCI Region ID](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm) 
	- eu-frankfurt-1, eu-paris-1, me-jeddah-1, us-ashburn-1, etc.

## Usage

Execute the script by running the following command in your terminal:

	
	curl https://raw.githubusercontent.com/Olygo/OCI-Fuse/main/oci_fuse.sh | bash

The script will prompt you to enter the following information:

- Local path to mount your OCI bucket
- Customer Secret Key ID and Secret
- OCI storage namespace
- OCI Region ID
- OCI bucket name
- Ask to enable FSTAB or not

The script will perform the following automatic setup steps:

- Check and create the local path if it does not exist
- Update the system and install the EPEL repository
- Install the s3fs-fuse tool
- Set API credentials in /etc/passwd-s3fs
- Mount the OCI bucket using s3fs
- Configure FSTAB if desired


## S3FS Features

* large subset of POSIX including reading/writing files, directories, symlinks, mode, uid/gid, and extended attributes
* allows random writes and appends
* large files via multi-part upload
* renames via server-side copy
* optional server-side encryption
* data integrity via MD5 hashes
* in-memory metadata caching
* local disk data caching
* user-specified regions
* authenticate via v2 or v4 signatures

## S3FS Manual Installation

Many systems provide pre-built packages:

* Oracle Linux 7 via EPEL:

  ```
  sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  sudo yum install s3fs-fuse
  ```

* Oracle Linux 8 via EPEL:

  ```
  sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  sudo yum install s3fs-fuse
  ```

* Oracle Linux 9 via EPEL:

  ```
  sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  sudo yum install s3fs-fuse
  ```

* Debian 9 and Ubuntu 16.04 or newer:

  ```
  sudo apt install s3fs
  ```

* RHEL and CentOS 7 or newer via EPEL:

  ```
  sudo yum install epel-release
  sudo yum install s3fs-fuse
  ```

## Mount examples for OCI

s3fs supports the standard
[OCI credentials](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2) and custom passwd file.

The default location for the s3fs password file can be created:

* using a `.passwd-s3fs` file in the users home directory (i.e. `${HOME}/.passwd-s3fs`)
* using the system-wide `/etc/passwd-s3fs` file

Enter your credentials in a file `${HOME}/.passwd-s3fs` and set
owner-only permissions:

```
echo OCI_ACCESS_KEY_ID:OCI_SECRET_ACCESS_KEY > ${HOME}/.passwd-s3fs
chmod 600 ${HOME}/.passwd-s3fs
```

Run s3fs with an existing bucket `mybucket`, directory `/mnt/mybucket`, region `Frankfurt`:

```
s3fs mybucket /mnt/mybucket -o passwd_file=${HOME}/.passwd-s3fs -o suid -o use_path_request_style -o url=https://{NAMESPACE}.compat.objectstorage.eu-frankfurt-1.oraclecloud.com -o endpoint=eu-frankfurt-1 
```

or

```
s3fs mybucket /mnt/mybucket -o passwd_file=${HOME}/.passwd-s3fs -o suid -o use_path_request_style -o multipart_size=128 -o parallel_count=50 -o multireq_max=100 -o max_background=1000 -o url=https://{NAMESPACE}.compat.objectstorage.eu-frankfurt-1.oraclecloud.com -o endpoint=eu-frankfurt-1 
```

If you encounter any errors, enable debug output adding:

```
s3fs ...  -o dbglevel=info -f -o curldbg
```

You can also mount on boot by entering the following line to `/etc/fstab`:

```
mybucket /path/to/mountpoint fuse.s3fs use_path_request_style,passwd_file=${HOME}/.passwd-s3fs,url=https://{NAMESPACE}.compat.objectstorage.eu-frankfurt-1.oraclecloud.com,endpoint=eu-frankfurt-1,_netdev,allow_other,uid=1000,gid=1000 0 0
```
or

```
mybucket /path/to/mountpoint fuse.s3fs use_path_request_style,passwd_file=${HOME}/.passwd-s3fs,url=https://{NAMESPACE}.compat.objectstorage.eu-frankfurt-1.oraclecloud.com,endpoint=eu-frankfurt-1,kernel_cache,multipart_size=128,parallel_count=50,multireq_max=100,max_background=1000,_netdev,allow_other,uid=1000,gid=1000 0 0
```

Note: You may also want to create the global credential file first

```
echo ACCESS_KEY_ID:SECRET_ACCESS_KEY > /etc/passwd-s3fs
chmod 600 /etc/passwd-s3fs
```

Note2: You may also need to make sure `netfs` service is start on boot

## S3FS Limitations

Generally S3 cannot offer the same performance or semantics as a local file system.  More specifically:

* random writes or appends to files require rewriting the entire object, optimized with multi-part upload copy
* metadata operations such as listing directories have poor performance due to network latency
* no atomic renames of files or directories
* no coordination between multiple clients mounting the same bucket
* no hard links
* inotify detects only local modifications, not external ones by other clients or tools

## S3FS Frequently Asked Questions

* [FAQ wiki page](https://github.com/s3fs-fuse/s3fs-fuse/wiki/FAQ)
* [s3fs on Stack Overflow](https://stackoverflow.com/questions/tagged/s3fs)
* [s3fs on Server Fault](https://serverfault.com/questions/tagged/s3fs)

## Questions ?
**_olygo.git@gmail.com_**


## Disclaimer
**Always test properly on test resources, before using anything on production resources to prevent unwanted outages or unwanted bills.**