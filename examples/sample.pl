#!/usr/bin/perl

use blib;
use FindBin;
use lib "$FindBin::Bin/../t";

use strict;
use warnings;

use Gtk2 qw(-init);
use Xacobeo::Simple;
use FindBin;

exit main();


sub main {

	my ($filename) = @ARGV;
	if (! defined $filename) {
		$filename = "$FindBin::Bin/../tests/sample.xml";
	}

	Xacobeo::Simple::render_document($filename);
	
	# Start the GUI's main loop
	Gtk2->main();

	return 0;
}
