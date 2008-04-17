#!perl -w

# $Id: pod-coverage.t 684 2004-09-30 23:16:47Z david $

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.06";
plan skip_all => "Test::Pod::Coverage 1.06 required for testing POD coverage"
  if $@;

all_pod_coverage_ok();
