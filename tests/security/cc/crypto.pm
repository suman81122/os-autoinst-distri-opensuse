# SUSE's openQA tests
#
# Copyright 2021 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Run 'crypto' test case of 'audit-test' test suite
# Maintainer: llzhao <llzhao@suse.com>
# Tags: poo#95485

use base 'consoletest';
use strict;
use warnings;
use testapi;
use utils;
use audit_test qw(run_testcase compare_run_log);

sub run {
    my ($self) = shift;

    select_console 'root-console';

    # Install certification-sles-eal4: needed by test case `crypto`
    zypper_call('in certification-sles-eal4');

    # Export MODE
    assert_script_run("export MODE=$audit_test::mode");

    # Run test case
    run_testcase('crypto', make => 1, timeout => 900);

    # Compare current test results with baseline
    my $result = compare_run_log('crypto');
    $self->result($result);
}

sub test_flags {
    return {always_rollback => 1};
}

1;
