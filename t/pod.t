#!perl -w

# $Id: pod.t 697 2004-10-02 19:58:38Z david $

use strict;
use Test::More;
eval "use Test::Pod 1.20";
plan skip_all => "Test::Pod 1.20 required for testing POD" if $@;
all_pod_files_ok(all_pod_files('bin', 'lib'));
