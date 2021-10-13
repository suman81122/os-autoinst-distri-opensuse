# SUSE's openQA tests
#
# Copyright 2017 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: gnome-clocks
# Summary: GNOME Clocks - Minimal Test
# Maintainer: Dominique Leuenberger <dimstar@suse.de>>

use base "x11test";
use strict;
use warnings;
use testapi;
use utils;

sub run {
    assert_gui_app('gnome-clocks');
}

1;
