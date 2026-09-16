[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#main-content)[](https://www.ibm.com/)

IBM Software Hub

Change version

Select

Filter on titles

- - [Welcome](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=dummy-landing-page-id)
        
    - [Overview](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=overview)
        
    - [Getting started](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=getting-started)
        
    - [Planning](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=planning)
        
    - [Installing](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=installing)
        
    - [Upgrading](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=upgrading)
        
    - [Services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services)
        
        - [AI services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-ai)
            
        - [Analytics services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-analytics)
            
        - [Dashboard services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-dashboard)
            
        - [Data governance services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-data-governance)
            
        - [Data management services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-data-management)
            
        - [Developer tool services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-developer-tool)
            
            - [Anaconda Repository for IBM Cloud Pak for Data](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-anaconda-repository-cloud-pak-data)
                
            - [RStudio Server Runtimes](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-rstudio-server-runtimes)
                
            - [Watson Studio Runtimes](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-watson-studio-runtimes)
                
                - [Installing](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=wsr-installing)
                    
                - [Upgrading](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=wsr-upgrading)
                    
                    - [Migrating notebooks and jobs that use outdated environments](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=upgrading-migrating-notebooks-jobs-that-use-outdated-environments)
                        
                    - [Upgrading from Version 5.1](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43)
                        
                    - [Upgrading from Version 5.2](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-52-49)
                        
                    - [Upgrading from Version 5.3](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-53-50)
                        
                    
                - [Getting started](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=wsr-getting-started)
                    
                - [Administering](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=wsr-administering)
                    
                - [Uninstalling](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=wsr-uninstalling)
                    
                
            
        - [Industry solutions services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-industry-solutions)
            
        - [Storage services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-storage)
            
        
    - [Administering](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=administering)
        
    - [cpd-cli command reference](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=cpd-cli-command-reference)
        
    - [Troubleshooting](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=troubleshooting)
        

[Announcements & sales manuals](https://www.ibm.com/docs/en/software-hub/5.3.x?announcement=all)

[](https://www.ibm.com/docs/en/offline)[](https://www.ibm.com/support/pages/node/7283484 "Opens in a new tab")

[Get hands-on experience with IBM tech  Join one of the largest technical IBM community gatherings!  →](https://www.ibm.com/events/techxchange)

1. [All products](https://www.ibm.com/docs/en/products)
2. [IBM Software Hub](https://www.ibm.com/docs/en/software-hub)
3. [5.3.x](https://www.ibm.com/docs/en/software-hub/5.3.x)

Was this topic helpful?

Focus sentinel

A newer version of this product documentation is available.

You are viewing an older version.

View latest

Focus sentinel

# Upgrading Watson Studio Runtimes from Version 5.1 to Version 5.3

Last Updated: 2026-05-21

An instance administrator can upgrade Watson Studio Runtimes from Version 5.1 to Version 5.3.

Who needs to complete this task?

Instance administrator To upgrade Watson Studio Runtimes, you must be an instance administrator. An instance administrator has permission to manage software in the following projects:

The operators project for the instance

The operators for this instance of IBM Software Hub are installed in the operators project. In the upgrade commands, the `${PROJECT_CPD_INST_OPERATORS}` environment variable refers to the operators project.

The operands project for the instance

The control plane and the services for this instance of IBM Software Hub are installed in the operands project. In the upgrade commands, the `${PROJECT_CPD_INST_OPERANDS}` environment variable refers to the operands project.

When do you need to complete this task?

Review the following options to determine whether you need to complete this task:

- If you want to upgrade the control plane and one or more services at the same time, follow the process in [Upgrading an instance of IBM Software Hub](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/upgrade/v51/upgrade-platform.html) instead.
- If you didn't upgrade Watson Studio Runtimes when you upgraded the control plane, complete this task to upgrade Watson Studio Runtimes.
    
    Repeat as needed If you are responsible for multiple instances of IBM Software Hub, you can repeat this task to upgrade more instances of Watson Studio Runtimes on the cluster.
    

## Information you need to complete this task[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__conref-L2-info-needed-title "Copy to clipboard")

Review the following information before you upgrade Watson Studio Runtimes:

Version requirements

All the components that are associated with an instance of IBM Software Hub must be installed at the same release. For example, if the control plane is at Version 5.3.1, you must upgrade Watson Studio Runtimes to Version 5.3.1.

Environment variables

The commands in this task use environment variables so that you can run the commands exactly as written.

- If you don't have the script that defines the environment variables, see [Setting up installation environment variables](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/install/collect-info-install-variables.html).
- To use the environment variables from the script, you must source the environment variables before you run the commands in this task. For example, run:
    
    ```bash
    source ./cpd_vars.sh
    ```
    

Storage requirements

You don't need to specify storage when you upgrade Watson Studio Runtimes.

## Before you begin[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__d81e246 "Copy to clipboard")

This task assumes that the following prerequisites are met:

System requirements

This task assumes that the cluster meets the minimum requirements for Watson Studio Runtimes.

|Where to find more information|
|---|
|If this task is not complete, see [System requirements](https://www.ibm.com/docs/en/SSNFH6_5.3.x/sys-reqs/overview-sys-reqs.html).|

In addition, ensure that you have the appropriate type and number of GPU for Watson Studio Runtimes.

|Where to find more information|
|---|
|If this task is not complete, see [GPU requirements](https://www.ibm.com/docs/en/SSNFH6_5.3.x/sys-reqs/model-reqs.html).|

Workstation

This task assumes that the workstation from which you will run the upgrade is set up as a client workstation and has the following command-line interfaces:

- IBM Software Hub CLI: `cpd-cli`
- OpenShift® CLI: `oc`
- Helm CLI: `oc`

|Where to find more information|
|---|
|If this task is not complete, see [Updating client workstations](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/upgrade/v51/setup-client.html).|

Control plane

This task assumes that the IBM Software Hub control plane is upgraded.

|Where to find more information|
|---|
|If this task is not complete, see [Upgrading an instance of IBM Software Hub](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/upgrade/v51/upgrade-platform.html).|

Private container registry

If your environment uses a private container registry (for example, your cluster is air-gapped), this task assumes that the following tasks are complete:

1. The Watson Studio Runtimes software images are mirrored to the private container registry.
    
    |Where to find more information|
    |---|
    |If this task is not complete, see [Mirroring images to a private container registry](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/upgrade/v51/prep-registry-mirror.html).|
    
2. The `cpd-cli` is configured to pull the `olm-utils-v4` image from the private container registry.
    
    |Where to find more information|
    |---|
    |If this task is not complete, see [Pulling the olm-utils-v4 image from the private container registry](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/upgrade/v51/prep-registry-get-image.html).|
    

GPU operators

This task assumes that the operators required to use GPUs are installed.

|Where to find more information|
|---|
|If this task is not complete, see [Installing operators for services that require GPUs](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/upgrade/v51/update-cluster-prereqs-gpu.html).|

Cluster-scoped resources

This task assumes that the cluster-scoped resources, such as custom resource definitions, cluster roles, and cluster role bindings, were updated.

|Where to find more information|
|---|
|If this task is not complete, see [Updating the cluster-scoped resources for the platform and services](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/upgrade/v51/prep-for-upgrade-crds.html).|

Image pull secrets

This task assumes that the secrets that contain the image pull credentials for the instance exist.

|Where to find more information|
|---|
|If this task is not complete, see [Creating image pull secrets for an instance of IBM Software Hub](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/upgrade/v51/upgrade-platform-secret.html).|

## Prerequisite services[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__recreate-section-prereq-svc__title__1 "Copy to clipboard")

Before you upgrade Watson Studio Runtimes, ensure that the following services are upgraded and running:

- [Watson Studio](https://www.ibm.com/docs/en/SSNFH6_5.3.x/svc-welcome/wsl.html)

## Procedure[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__recreate-section-procedure__title__1 "Copy to clipboard")

Complete the following tasks to upgrade Watson Studio Runtimes:

1. [Specifying installation options](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__adv-config)
2. [Upgrading the service](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__svc)
3. [Validating the upgrade](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__validate)
4. [What to do next](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__next-steps)

## Specifying installation options[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__adv-config__title__1 "Copy to clipboard")

When you upgrade Watson Studio Runtimes, specify the runtimes you want installed and kept in the `install-options.yml` file in the `work` directory.

Important: If you want to upgrade all existing runtimes automatically when you upgrade Watson Studio, specify the `ws_runtimes` component when you upgrade Watson Studio.

If you do not specify the `ws_runtimes` component when you upgrade Watson Studio, only the default runtime is upgraded. You must upgrade the non-default runtimes manually.

Follow the appropriate guidance for the version of IBM Software Hub that you installed:

Version 5.3.1

5.3.1 and later The formatting applies only to IBM Software Hub Version 5.3.1.

Retain the `---` syntax at the beginning of the entry to ensure that this entry is treated as a separate document.

```yaml
---
# ............................................................................
# Watson Studio Runtimes parameters
# ............................................................................
non_olm:
  wsRuntimes:
    kinds: []
```

Version 5.3.0

If you want to install one or more optional runtimes, add the parameters to the **`non_olm:`** section of the `install-options.yml` file under the `wsRuntimes:` entry.

```yaml
# ............................................................................
# Watson Studio Runtimes parameters
# ............................................................................
  wsRuntimes:
    kinds: []
```

|Property|Description|
|---|---|
|`kinds`|Specify whether you want to install optional Watson Studio Runtimes for GPU and R.<br><br>Default value<br><br>`[]`<br><br>Valid values<br><br>`ibm-cpd-ws-runtime-251-pygpu`<br><br>Install Runtime 25.1 on Python 3.12 for GPU.<br><br>`ibm-cpd-ws-runtime-241-pygpu`<br><br>Install Runtime 24.1 on Python 3.11 for GPU.<br><br>`ibm-cpd-ws-runtime-251-r`<br><br>Install Runtime 25.1 on R 4.4.<br><br>`ibm-cpd-ws-runtime-241-r`<br><br>Install Runtime 24.1 on R 4.3.<br><br>Including this parameter<br><br>Specify the runtime name as a list item on a new line.<br><br>Install Runtime 25.1 on Python 3.12 for GPU<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-251-pygpu<br>```<br><br>Install Runtime 24.1 on Python 3.11 for GPU<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-241-pygpu<br>```<br><br>Install Runtime 25.1 on R 4.4<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-251-r<br>```<br><br>Install Runtime 24.1 on R 4.3<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-241-r<br>```<br><br>Install all runtimes<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-251-pygpu<br>      - ibm-cpd-ws-runtime-241-pygpu<br>      - ibm-cpd-ws-runtime-251-r<br>      - ibm-cpd-ws-runtime-241-r<br>```|

## Upgrading the service[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__d81e707 "Copy to clipboard")

To upgrade Watson Studio Runtimes:

1. Log the `cpd-cli` in to the Red Hat® OpenShift Container Platform cluster:
    
    ```bash
    ${CPDM_OC_LOGIN}
    ```
    
    Remember: `CPDM_OC_LOGIN` is an alias for the `cpd-cli manage login-to-ocp` command.
    
2. Update the operator and custom resource for Watson Studio Runtimes.
    
    ```bash
    cpd-cli manage install-components \
    --license_acceptance=true \
    --components=ws_runtimes \
    --release=${VERSION} \
    --patch_id=${PATCH_ID} \
    --operator_ns=${PROJECT_CPD_INST_OPERATORS} \
    --instance_ns=${PROJECT_CPD_INST_OPERANDS} \
    --image_pull_prefix=${IMAGE_PULL_PREFIX} \
    --image_pull_secret=${IMAGE_PULL_SECRET} \
    --param-file=/tmp/work/install-options.yml \
    --upgrade=true
    ```
    

## Validating the upgrade[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__d81e813 "Copy to clipboard")

Watson Studio Runtimes is upgraded when the `install-components` command returns:

```plaintext-ibm
[SUCCESS]... The install-components command ran successfully
```

If you want to confirm that the custom resource status is `Completed`, you can run the `cpd-cli manage get-cr-status` command:

```bash
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=ws_runtimes
```

## What to do next[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__next-steps__title__1 "Copy to clipboard")

1. Upgrade all of the services in this instance to IBM Software Hub Version 5.3.x.
2. Complete the [`catalog-api` service migration to PostgreSQL](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/admin/post-install-services-catalog-api-migration.html).
3. If you use custom runtime images in Watson Studio, you must create and register the custom images to rebase the image with the latest IBM Software Hub runtime image. See [Building custom runtime images](https://www.ibm.com/docs/en/SSNFH6_5.3.x/svc-wsruntimes/build-cust-images.html "Build custom runtime images to optimize the standard software configuration of a runtime for your application needs. For example, if you work in an air-gapped environment which forbids exposing any operations to the Internet, you might want to create your own, custom runtime image.").

After you complete the preceding steps, Watson Studio Runtimes is ready to use. For details, see [Notebook environments](https://www.ibm.com/docs/en/SSQNUZ_5.3.x/wsj/analyze-data/notebook-environments.html).

**Parent topic:**

[Upgrading Watson Studio Runtimes](https://www.ibm.com/docs/en/SSNFH6_5.3.x/svc-wsruntimes/ws-runtimes-upgrade.html "An instance administrator can upgrade the Watson Studio Runtimes service.")

While IBM values the use of inclusive language, terms that are outside of IBM's direct influence, for the sake of maintaining user understanding, are sometimes required. As other industry leaders join IBM in embracing the use of inclusive language, IBM will continue to update the documentation to reflect those changes.

© Copyright IBM Corporation 2026

[](https://www.ibm.com/)

[Contact IBM](https://www.ibm.com/contact?lnk=flg-cont-usen) [Privacy](https://www.ibm.com/us-en/privacy) [Terms of use](https://www.ibm.com/legal?lnk=flg-tous-usen) [Accessibility](https://www.ibm.com/able/?lnk=flg-acce-usen) Cookie Preferences

- [IBM Documentation Help](https://www.ibm.com/docs/en/about)

- On this page
- [Information you need to complete this task](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__conref-L2-info-needed-title)
    
- [Before you begin](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__d81e246)
    
- [Prerequisite services](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__recreate-section-prereq-svc__title__1)
    
- [Procedure](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__recreate-section-procedure__title__1)
    
- [Specifying installation options](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__adv-config__title__1)
    
- [Upgrading the service](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__d81e707)
    
- [Validating the upgrade](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__d81e813)
    
- [What to do next](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__next-steps__title__1)
```yaml
# ............................................................................
# Watson Studio Runtimes parameters
# ............................................................................
  wsRuntimes:
    kinds: []
```

|Property|Description|
|---|---|
|`kinds`|Specify whether you want to install optional Watson Studio Runtimes for GPU and R.<br><br>Default value<br><br>`[]`<br><br>Valid values<br><br>`ibm-cpd-ws-runtime-251-pygpu`<br><br>Install Runtime 25.1 on Python 3.12 for GPU.<br><br>`ibm-cpd-ws-runtime-241-pygpu`<br><br>Install Runtime 24.1 on Python 3.11 for GPU.<br><br>`ibm-cpd-ws-runtime-251-r`<br><br>Install Runtime 25.1 on R 4.4.<br><br>`ibm-cpd-ws-runtime-241-r`<br><br>Install Runtime 24.1 on R 4.3.<br><br>Including this parameter<br><br>Specify the runtime name as a list item on a new line.<br><br>Install Runtime 25.1 on Python 3.12 for GPU<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-251-pygpu<br>```<br><br>Install Runtime 24.1 on Python 3.11 for GPU<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-241-pygpu<br>```<br><br>Install Runtime 25.1 on R 4.4<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-251-r<br>```<br><br>Install Runtime 24.1 on R 4.3<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-241-r<br>```<br><br>Install all runtimes<br><br>```yaml<br>  wsRuntimes:<br>    kinds:<br>      - ibm-cpd-ws-runtime-251-pygpu<br>      - ibm-cpd-ws-runtime-241-pygpu<br>      - ibm-cpd-ws-runtime-251-r<br>      - ibm-cpd-ws-runtime-241-r<br>```|

## Upgrading the service[](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-51-43#cli-upgrade__d81e707 "Copy to clipboard")


