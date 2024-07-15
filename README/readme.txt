Created and configured a demo environment mimicking bank’s lower environment on AWS using Terraform:

    - Network (VPC, subnets, IGW, Route Table) setup.
    - Instances:
    - Windows EC2 instance mimicking the server where units are being delivered to the bank.
    - Linux EC2 instance for Jenkins.
    - Linux EC2 instance mimicking an App server node where the units should be deployed.
    - assigned fixed private IP addresses to Instances.
    - created and assigned appropriate Security Groups for Instances: 
    - opening ports for RDP / SSH / HTTP ingress access to Instances, 
    - and inter-Instance communication.
    - opening ports for egress communication (to setup Jenkins, etc).



Confgured launched instances (using Terraform user_data):

    - on Windows instance (using PowerShell):
        - installed OpenSSH server (for inter-instance communication).
        - set the OpenSSH service to start automatically.
        - disabled Windows Defender Firewall for the private network.
        - updated ssh config (set public key authentication, create authorized keys dir, file and entries).
    - created directories and dummy units for deployment (so they don’t have to be created manually on every destroy/apply).

    - on Linux dummy App server node instance (using Bash):
        - created a destination dir to which unit files should be deployed.
        - added the public key to authorized_keys (for inter-instance communication).

    - on Linux Jenkins instance (using Bash):
        - installed Jenkins and set the service to run automatically.
        - installed Java and Git.
        - created the private key (for inter-instance communication).
        - gave Jenkins ownership on the key, set permissions.
        - setup and configured known_hosts, gave ownership and permissions to Jenkins.



Created a demo automation for deploying Frontend units:

    - configured needed Jenkins plugins (Publish over SSH, SSH Agent).
    - configured Git credentials in Jenkins.
    - confgured a Jenkins pipeline (using a Groovy script) to:
        - clone the GitHub repo Master branch locally (current / pre-deployment server situation).
        - fetch files from the Windows instance (overwritting any files in the locally cloned repo).
        - push the altered repo back to GitHub.
        - deploy the units to the Linux dummy App server node instance (using Bash, scp).
