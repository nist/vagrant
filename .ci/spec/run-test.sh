#!/usr/bin/env bash

# packet and job configuration
export SLACK_USERNAME="Vagrant"
export SLACK_ICON="https://media.giphy.com/media/yIQ5glQeheYE0/200.gif"
export SLACK_TITLE="Vagrant-Spec Test Runner"
export PACKET_EXEC_DEVICE_NAME="${PACKET_EXEC_DEVICE_NAME:-spec-ci-boxes}"
export PACKET_EXEC_DEVICE_SIZE="${PACKET_EXEC_DEVICE_SIZE:-baremetal_0,baremetal_1,baremetal_1e}"
export PACKET_EXEC_PREFER_FACILITIES="${PACKET_EXEC_PREFER_FACILITIES:-iad1,iad2,ewr1,dfw1,dfw2,sea1,sjc1,lax1}"
export PACKET_EXEC_OPERATING_SYSTEM="${PACKET_EXEC_OPERATING_SYSTEM:-ubuntu_18_04}"
export PACKET_EXEC_PRE_BUILTINS="${PACKET_EXEC_PRE_BUILTINS:-InstallVagrant,InstallVirtualBox,InstallVmware,InstallHashiCorpTool,InstallVagrantVmware}"
export PACKET_EXEC_QUIET="1"
export PKT_VAGRANT_CLOUD_TOKEN="${VAGRANT_CLOUD_TOKEN}"
export VAGRANT_PKG_VERSION="2.2.7" # need to figure out how to make this latest instead
###


csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/common.sh"

pushd "${root}" > "${output}"

# Assumes packet is already set up

# Define a custom cleanup function to destroy any orphan guests
# on the packet device
function cleanup() {
    (>&2 echo "Cleaning up packet device")
    unset PACKET_EXEC_PERSIST
    pkt_wrap_stream "cd vagrant;VAGRANT_CWD=test/vagrant-spec/ VAGRANT_VAGRANTFILE=Vagrantfile.spec vagrant destroy -f" \
                "Vagrant command failed"
}

# job_id is provided by common.sh
export PACKET_EXEC_REMOTE_DIRECTORY="${job_id}"
export PACKET_EXEC_PERSIST="1"

# spec test configuration, defined by action runners, used by Vagrant on packet
export PKT_VAGRANT_HOST_BOXES="${VAGRANT_HOST_BOXES}"
export PKT_VAGRANT_GUEST_BOXES="${VAGRANT_GUEST_BOXES}"
###

echo "Syncing up remote packet device for current job... "
# NOTE: We only need to call packet-exec with the -upload option once
#       since we are persisting the job directory. This command
#       is used simply to seed the work directory.
wrap_stream packet-exec run -upload -- /bin/true \
            "Failed to setup project on remote packet instance"

# Run the job

echo "Running vagrant spec tests..."
# Need to make memory customizable for windows hosts
pkt_wrap_stream "cd vagrant;VAGRANT_HOST_MEMORY=5000 VAGRANT_CWD=test/vagrant-spec/ VAGRANT_VAGRANTFILE=Vagrantfile.spec vagrant up --provider vmware_desktop" \
                "Vagrant command failed"


echo "Finished vagrant spec tests"
