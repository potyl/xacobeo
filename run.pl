#!/usr/bin/perl

use strict;
use warnings;

use blib;
use lib '.';

use Xacobeo::Conf;
Xacobeo::Conf->init('.');

my $return = do 'bin/xacobeo';
if ($@) {
    die "Failed to load xacobeo; $@";
}
if (! defined $return) {
    die "Error loading xacobeo; $!";
}

main();
