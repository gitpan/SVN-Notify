#!perl -w

# $Id: pod.t 4750 2010-01-16 04:32:23Z david $

use strict;
use Test::More;
eval "use Test::Pod 1.41";
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;
all_pod_files_ok(all_pod_files('bin', 'lib'));
