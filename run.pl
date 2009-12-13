#!/usr/bin/perl

use strict;
use warnings;

use blib;
use lib 'lib';
use lib 'examples';

use Xacobeo::Conf;


exit main2() unless caller;


sub main2 {
	Xacobeo::Conf->init('.');

	my $return = do 'bin/xacobeo';
	if ($@) {
		die "Failed to load xacobeo; $@";
	}
	elsif (! defined $return) {
		die "Error loading xacobeo; $!";
	}

	goto &main;
	return 0;
}
