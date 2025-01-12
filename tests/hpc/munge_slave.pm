# SUSE's openQA tests
#
# Copyright 2016-2018 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Installation of munge package from HPC module and sanity check
# of this package
# Maintainer: soulofdestiny <mgriessmeier@suse.com>

use base 'hpcbase';
use strict;
use warnings;
use testapi;
use lockapi;
use utils;

sub run {
    my $self = shift;

    # install munge, wait for master and munge key
    zypper_call('in munge');
    barrier_wait('MUNGE_INSTALLATION_FINISHED');
    barrier_wait('MUNGE_KEY_COPIED');

    # start and enable munge
    $self->enable_and_start('munge');
    barrier_wait("MUNGE_SERVICE_ENABLED");

    # wait for master to finish
    barrier_wait('MUNGE_DONE');
}

sub post_fail_hook {
    my ($self) = @_;
    $self->select_serial_terminal;
    $self->upload_service_log('munge');
}

1;
