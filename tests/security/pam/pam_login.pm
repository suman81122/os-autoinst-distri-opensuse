# Copyright 2020 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Summary: PAM tests for login, user login should fail without authentication
# Maintainer: rfan1 <richard.fan@suse.com>
# Tags: poo#70345, tc#1767577

use base 'opensusebasetest';
use strict;
use warnings;
use testapi;

sub run {
    my $self = shift;
    $self->select_serial_terminal;

    # Define the user and password, which are already configured in previous milestone
    my $user = 'suse';
    my $passwd = 'susetesting';

    # Modify the login/sshd files to set the PAM authentication
    my $deny_user_file = '/etc/deniedusers';
    my $pam_sshd = '/etc/pam.d/sshd';
    my $pam_login = '/etc/pam.d/login';
    my $pam_sshd_bak = '/tmp/sshd_bak';
    my $pam_login_bak = '/tmp/login_bak';
    assert_script_run "echo $user > $deny_user_file";
    assert_script_run "cp $pam_sshd $pam_sshd_bak";
    assert_script_run "cp $pam_login $pam_login_bak";
    assert_script_run "sed -i '\$a auth      required   pam_listfile.so   onerr=succeed  item=user  sense=deny  file=$deny_user_file' $pam_sshd";
    assert_script_run "sed -i '\$a auth      required   pam_listfile.so   onerr=succeed  item=user  sense=deny  file=$deny_user_file' $pam_login";
    upload_logs($pam_sshd);
    upload_logs($pam_login);

    # Try to login to the OS with user suse, access should fail
    assert_script_run(
        "expect -c 'spawn ssh $user\@localhost; \\
expect \"Password: \"; send \"$passwd\\n\"; \\
expect \"Password: \"; send \"$passwd\\n\"; \\
expect \"Password: \"; send \"$passwd\\n\"; \\
expect \"*password: \"; send \"$passwd\\n\"; \\
expect \"*password: \"; send \"$passwd\\n\"; \\
expect {
    \"*authentication failures\" {
      exit 0
   }
   eof {
       exit 1
   }
}'"
    );

    # Make sure your current user is not "suse"
    validate_script_output "whoami | grep $user|| echo 'check pass'", sub { m/check pass/ };

    # Make sure login can succeed for user who is not defined in deny user file
    my $new_user = 'bernhard';
    assert_script_run "ssh -4v $new_user\@localhost bash -c 'whoami | grep $new_user'";

    # Tear down, clear pam configuration changes
    assert_script_run "rm -rf $deny_user_file";
    assert_script_run "mv $pam_sshd_bak $pam_sshd";
    assert_script_run "mv $pam_login_bak $pam_login";
}

sub test_flags {
    return {always_rollback => 1};
}

sub post_fail_hook {
    assert_script_run 'cp -pr /mnt/pam.d /etc';
}

1;
