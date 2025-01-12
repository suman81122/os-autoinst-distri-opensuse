# XEN regression tests
#
# Copyright 2019 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: libvirt-client nmap
# Summary: Test if the guests can be saved and restored, by adding a
# temp file and restoring to a state before the file existed.
# Maintainer: Jan Baier <jbaier@suse.cz>

use base "virt_feature_test_base";
use virt_autotest::common;
use virt_autotest::utils;
use strict;
use warnings;
use testapi;
use utils;

sub run_test {
    assert_script_run "mkdir -p /var/lib/libvirt/images/saves/";

    record_info "Remove", "Remove previous saves (if there were any)";
    script_run "rm /var/lib/libvirt/images/saves/$_.vmsave || true" foreach (keys %virt_autotest::common::guests);

    record_info "Save", "Save the machine states";
    assert_script_run("virsh save $_ /var/lib/libvirt/images/saves/$_.vmsave", 300) foreach (keys %virt_autotest::common::guests);

    record_info "Check", "Check saved states";
    foreach my $guest (keys %virt_autotest::common::guests) {
        if (script_run("virsh list --all | grep $guest | grep shut") != 0) {
            record_soft_failure "Guest $guest should be shut down now";
            script_run "virsh destroy $guest", 90;
        }
    }

    # Starting all guests to create a test file in them, the file must not exist after restoring.
    start_guests();

    record_info "SSH", "Check hosts are listening on SSH";
    wait_guest_online($_) foreach (keys %virt_autotest::common::guests);

    foreach my $guest (keys %virt_autotest::common::guests) {
        assert_script_run("ssh root\@$guest 'touch /var/empty_temp_file'");
    }

    # Guest must be in power down state to be restored
    shutdown_guests();

    record_info "Restore", "Restore guests";
    assert_script_run("virsh restore /var/lib/libvirt/images/saves/$_.vmsave", 300) foreach (keys %virt_autotest::common::guests);

    record_info "Check", "Check restored states";
    assert_script_run "virsh list --all | grep $_ | grep running" foreach (keys %virt_autotest::common::guests);

    record_info "SSH", "Check hosts are listening on SSH";
    ensure_online($_) foreach (keys %virt_autotest::common::guests);

    record_info "Check", "Restored guests validation";
    foreach my $guest (keys %virt_autotest::common::guests) {
        if (script_run("ssh root\@$guest 'test -f /var/empty_temp_file'") != 1) {
            die "The temp file should not exist in the restored state.";
        }
    }
}

1;
