IBM Software Hub
Change version
Select
Filter on titles

        Welcome
        Overview
        Getting started
        Planning
        Installing
            Setting up a client workstation
                Installing the IBM Software Hub CLI
                Installing the OpenShift CLI
                Installing the Helm CLI
            Setting up a cluster
                Installing Red Hat OpenShift
                Installing the cert-manager Operator
                Installing persistent storage
                Setting up a private container registry
            Collecting required information
                Obtaining your IBM entitlement API key
                Determining which components to install
                Determining which models and optional images to mirror
                Setting up installation environment variables
            Preparing to run installs in a restricted network
                Obtaining the olm-utils-v4 image
                Downloading CASE packages
            Preparing to run installs from a private container registry
                Mirroring images to a private container registry
                Configuring an image digest mirror set
                Pulling the olm-utils-v4 image from the private container registry
            Preparing your cluster
                Updating the global image pull secret
                Creating the required projects (namespaces) for the shared cluster components
                Creating cluster-scoped resources for shared cluster components
                Creating image pull secrets for shared cluster components
                Installing shared cluster components
                Configuring persistent storage
                Creating custom SCCs for services
                Changing required node settings
                Installing prerequisite software
            Preparing to install an instance of IBM Software Hub
                Checking the health of your cluster
                Creating the required projects (namespaces)
                Creating cluster-scoped resources
                Applying the required permissions to projects (namespaces)
                Authorizing an instance administrator
                Enabling event-driven automatic scaling
                Creating secrets for services that use Multicloud Object Gateway
                Installing the IBM Events Operator
                Annotating projects for embedded Db2 databases
                Enabling Analytics Engine powered by Apache Spark to pre-pull images
                Enabling access to watsonx Orchestrate images for use with the ADK
            Installing an instance of IBM Software Hub
                Creating image pull secrets for the instance
                Installing IBM Software Hub
                Tethering projects to the control plane
            Setting up IBM Software Hub
            Installing solutions and services
                Specifying installation options for services
                Specifying the privileges that Db2U runs with
                Running a batch installation of solutions and services
            Installing IBM Software Hub Control Center
            Setting up a remote physical location
            Uninstalling the platform and services
        Upgrading
        Services
            AI services
            Analytics services
            Dashboard services
            Data governance services
            Data management services
                Data Gate
                Data Replication
                Data Virtualization
                Db2
                    Preparing to install
                    Installing
                    Post-installation setup
                    Upgrading
                        Upgrading from Version 5.1
                        Upgrading from Version 5.2
                        Upgrading from Version 5.3
                        Upgrading database instances with HADR
                    Administering
                    Getting started
                    Uninstalling
                    Db2 REST service
                Db2 Data Management Console
                Db2 Warehouse
                EDB Postgres
                Informix
                MongoDB
                Unstructured Data Integration
                watsonx.data
                watsonx.data Premium
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
Obtaining the olm-utils-v4 image before running IBM Software Hub installation commands in a restricted network
Last Updated: 2026-03-30

If your cluster is in a restricted network, you must ensure that a supported version of the olm-utils-v4 image is on the client workstation from which you will run the installation commands. The version that corresponds to the version of IBM Software Hub that you are installing is recommended.

Installation phase

        You are not here. Setting up a client workstation
        You are not here. Setting up a cluster
        You are not here. Collecting required information
        You are not here. Preparing to run installs in a restricted network
        You are here icon. Preparing to run installs from a private container registry
        You are not here. Preparing the cluster for IBM Software Hub
        You are not here. Preparing to install an instance of IBM Software Hub
        You are not here. Installing an instance of IBM Software Hub
        You are not here. Setting up the control plane
        You are not here. Installing solutions and services

Who needs to complete this task?

    All administrators Cluster administrators, registry administrators, and instance administrators must complete this task.
When do you need to complete this task?

    In a restricted network, you must ensure that you have the olm-utils-v4 image on your client workstation.

    You have the following choices for completing this task:

        One-time setup If you plan to mirror the IBM Software Hub software images to a private container registry, the registry administrator can complete this task before they mirror the images. Then, other users can pull the image from the private container registry.
        Repeat as needed If you plan to pull the images from the IBM Entitled Registry, complete this task on each workstation that will be used to perform installation tasks.

Procedure

The steps that you complete depend on whether you plan to use the same workstation in the cluster network and which image you are entitled to use:
You plan to use the same workstation inside the cluster network

You plan to use a different workstation inside the cluster network

What to do next

Now that you've made the olm-utils-v4 image or the olm-utils-premium-v4 image available on the client workstation, you're ready to complete Downloading CASE packages before running IBM Software Hub installation commands in a restricted network.
Parent topic:
Preparing to run IBM Software Hub installation commands in a restricted network
Next topic:
Downloading CASE packages before running IBM Software Hub installation commands in a restricted network
Related reference

    cpd-cli manage save-image
    cpd-cli manage load-image

While IBM values the use of inclusive language, terms that are outside of IBM's direct influence, for the sake of maintaining user understanding, are sometimes required. As other industry leaders join IBM in embracing the use of inclusive language, IBM will continue to update the documentation to reflect those changes.
© Copyright IBM Corporation 2026

    Contact IBM
    Privacy
    Terms of use
    Accessibility

    IBM Documentation Help

    On this page
    Procedure
    What to do next
