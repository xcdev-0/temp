

IBM Software Hub
Change version
Select
Filter on titles

        Welcome
        Overview
        Getting started
        Planning
        Installing
        Upgrading
        Services
            AI services
                AI Factsheets
                IBM Master Data Management
                Orchestration Pipelines
                Synthetic Data Generator
                Voice Gateway
                Watson Assistant for Voice Interaction
                Watson Discovery
                Watson Machine Learning
                Watson OpenScale
                    Installing
                    Upgrading
                        Upgrading from Version 5.1
                        Upgrading from Version 5.2
                        Upgrading from Version 5.3
                    Administering
                    Getting started
                    Uninstalling
                Watson Speech services
                Watson Studio
                watsonx.ai
                watsonx Assistant
                watsonx BI
                watsonx Code Assistant
                watsonx Code Assistant for Red Hat Ansible Lightspeed
                watsonx Code Assistant for Z
                watsonx Code Assistant for Z Agentic
                watsonx Code Assistant for Z Code Explanation
                watsonx Code Assistant for Z Code Generation
                watsonx Code Assistant for Z Understand
                watsonx.governance
                watsonx Orchestrate
            Analytics services
            Dashboard services
            Data governance services
            Data management services
            Developer tool services
            Industry solutions services
            Storage services
        Administering
        cpd-cli command reference
        Troubleshooting

Announcements & sales manuals

Get hands-on experience with IBM tech  Join one of the largest technical IBM community gatherings!  →

    All products
    IBM Software Hub
    5.3.x

Was this topic helpful?

Focus sentinel
A newer version of this product documentation is available.
You are viewing an older version.
View latest
Focus sentinel
Upgrading Watson OpenScale from Version 5.1.x to Version 5.3
Last Updated: 2026-05-21

An instance administrator can upgrade Watson OpenScale from Version 5.1 to Version 5.3.

Who needs to complete this task?

    Instance administrator To upgrade Watson OpenScale, you must be an instance administrator. An instance administrator has permission to manage software in the following projects:

    The operators project for the instance

        The operators for this instance of Watson OpenScale are installed in the operators project. In the upgrade commands, the ${PROJECT_CPD_INST_OPERATORS} environment variable refers to the operators project.
    The operands project for the instance

        The custom resources for the control plane and Watson OpenScale are installed in the operands project. In the upgrade commands, the ${PROJECT_CPD_INST_OPERANDS} environment variable refers to the operands project.

When do you need to complete this task?

    Review the following options to determine whether you need to complete this task:

        If you want to upgrade the IBM Software Hub control plane and one or more services at the same time, follow the process in Upgrading an instance of IBM Software Hub instead.
        If you didn't upgrade Watson OpenScale when you upgraded the IBM Software Hub control plane, complete this task to upgrade Watson OpenScale.

        Repeat as needed If you are responsible for multiple instances of IBM Software Hub, you can repeat this task to upgrade more instances of Watson OpenScale on the cluster.

Information you need to complete this task

Review the following information before you upgrade Watson OpenScale:

Version requirements

    All the components that are associated with an instance of IBM Software Hub must be installed at the same release. For example, if the IBM Software Hub control plane is at Version 5.3.1, you must upgrade Watson OpenScale to Version 5.3.1.

Environment variables
    The commands in this task use environment variables so that you can run the commands exactly as written.

        If you don't have the script that defines the environment variables, see Setting up installation environment variables.
        To use the environment variables from the script, you must source the environment variables before you run the commands in this task. For example, run:

        source ./cpd_vars.sh

Before you begin

This task assumes that the following prerequisites are met:

System requirements
    This task assumes that the cluster meets the minimum requirements for Watson OpenScale.
    Where to find more information
    If this task is not complete, see System requirements.
Workstation
    This task assumes that the workstation from which you will run the upgrade is set up as a client workstation and has the following command-line interfaces:

        IBM Software Hub CLI: cpd-cli
        OpenShift® CLI: oc
        Helm CLI: oc

    Where to find more information
    If this task is not complete, see Updating client workstations.
Control plane
    This task assumes that the IBM Software Hub control plane is upgraded.
    Where to find more information
    If this task is not complete, see Upgrading an instance of IBM Software Hub.
Private container registry
    If your environment uses a private container registry (for example, your cluster is air-gapped), this task assumes that the following tasks are complete:

        The Watson OpenScale software images are mirrored to the private container registry.
        Where to find more information
        If this task is not complete, see Mirroring images to a private container registry.
        The cpd-cli is configured to pull the olm-utils-v4 image from the private container registry.
        Where to find more information
        If this task is not complete, see Pulling the olm-utils-v4 image from the private container registry.

Cluster-scoped resources
    This task assumes that the cluster-scoped resources, such as custom resource definitions, cluster roles, and cluster role bindings, were updated.
    Where to find more information
    If this task is not complete, see Updating the cluster-scoped resources for the platform and services.
Image pull secrets
    This task assumes that the secrets that contain the image pull credentials for the instance exist.
    Where to find more information
    If this task is not complete, see Creating image pull secrets for an instance of IBM Software Hub.

Procedure

Complete the following tasks to upgrade Watson OpenScale:

    Upgrading the service
    Validating the upgrade
    Upgrading existing service instances
    What to do next

Upgrading the service

To upgrade Watson OpenScale:

    Log the cpd-cli in to the Red Hat® OpenShift Container Platform cluster:

    ${CPDM_OC_LOGIN}

    Remember: CPDM_OC_LOGIN is an alias for the cpd-cli manage login-to-ocp command.
    Update the operator and custom resource for Watson OpenScale.

    cpd-cli manage install-components \
    --license_acceptance=true \
    --components=openscale \
    --release=${VERSION} \
    --patch_id=${PATCH_ID} \
    --operator_ns=${PROJECT_CPD_INST_OPERATORS} \
    --instance_ns=${PROJECT_CPD_INST_OPERANDS} \
    --image_pull_prefix=${IMAGE_PULL_PREFIX} \
    --image_pull_secret=${IMAGE_PULL_SECRET} \
    --upgrade=true

Validating the upgrade
Watson OpenScale is upgraded when the install-components command returns:

[SUCCESS]... The install-components command ran successfully

If you want to confirm that the custom resource status is Completed, you can run the cpd-cli manage get-cr-status command:
Upgrading existing service instances

The service instances are automatically upgraded when you upgrade Watson OpenScale.
What to do next

Watson OpenScale is ready to use.
Parent topic:
Upgrading the Watson OpenScale service
While IBM values the use of inclusive language, terms that are outside of IBM's direct influence, for the sake of maintaining user understanding, are sometimes required. As other industry leaders join IBM in embracing the use of inclusive language, IBM will continue to update the documentation to reflect those changes.
© Copyright IBM Corporation 2026

    Contact IBM
    Privacy
    Terms of use
    Accessibility

    IBM Documentation Help

    On this page
    Information you need to complete this task
    Before you begin
    Procedure
    Upgrading the service
    Validating the upgrade
    Upgrading existing service instances
    What to do next

