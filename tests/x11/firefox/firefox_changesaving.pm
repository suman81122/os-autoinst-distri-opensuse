# SUSE's openQA tests
#
# Copyright 2009-2013 Bernhard M. Wiedemann
# Copyright 2012-2019 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: MozillaFirefox
# Summary: Case#1436111: Firefox: Preferences Change Saving
# - Launch xterm, kill firefox, cleanup previous firefox configuration, launch
# firefox
# - Switch back to xterm (alt-tab), run "ll --time-style=full-iso
# .mozilla/firefox/*.default/prefs.js | cut -d' ' -f7 " and save output to a
# file
# - Save screenshot
# - Open firefox preferences
# - Change firefox start to "Show a blank page"
# - Run "ll --time-style=full-iso
# .mozilla/firefox/*.default/prefs.js | cut -d' ' -f7" again and save to a new
# file
# - Compare timestamps recorded
# - Exit firefox
# Maintainer: wnereiz <wnereiz@gmail.com>

use strict;
use warnings;
use base "x11test";
use testapi;
use version_utils 'is_sle';

sub run {

    my ($self) = @_;
    my $changesaving_checktimestamp = "ll --time-style=full-iso .mozilla/firefox/*default*/prefs.js | cut -d' ' -f7";

    $self->start_firefox_with_profile;

    send_key "alt-tab";    #Switch to xterm
    wait_still_screen 2, 4;
    assert_script_run "$changesaving_checktimestamp > dfa";
    wait_still_screen 2, 4;
    send_key "alt-tab";    #Switch to firefox
    wait_still_screen 2, 4;
    save_screenshot;

    # Open a new tab to avoid the keyboard focus is misled by the homepage
    send_key 'ctrl-t';
    wait_still_screen 3;
    send_key "alt-e";
    wait_still_screen 3;
    send_key "n";
    assert_screen('firefox-preferences');
    assert_and_click 'firefox-changesaving-showblankpage';
    wait_still_screen 2, 4;    #There might be a notification
    send_key "alt-tab";        #Switch to xterm
    wait_still_screen 2, 4;
    assert_screen 'xterm-left-open';

    assert_script_run "$changesaving_checktimestamp > dfb";

    # check and fail if timestamp is same
    assert_script_run 'grep -v $(cat dfa) dfb';

    # restore previous settings, start with home page
    assert_script_run 'cp dfa dfb';
    assert_script_run 'rm -vf df*';    #Clear

    send_key_until_needlematch 'firefox-preferences', 'alt-tab';    #Switch to firefox

    $self->exit_firefox;
}
1;
