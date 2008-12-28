#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use FindBin;
use lib "$FindBin::Bin";

BEGIN { use_ok('Xacobeo::XS') };
use Xacobeo::Simple;

use Glib qw(TRUE FALSE);
use Gtk2 qw(-init);
use FindBin;
use File::Slurp qw(slurp);
use Encode 'decode';

exit tests();


sub tests {
	
	
	foreach my $file ('sample.xml') {

		my $filename = File::Spec->catfile($FindBin::Bin, File::Spec->updir, 'tests', $file);

		my ($textview) = Xacobeo::Simple::render_document($filename);
		my $buffer = $textview->get_buffer;
		my $text = $buffer->get_text($buffer->get_start_iter, $buffer->get_end_iter, TRUE);
	
		my $expected = expected($filename);
		if ($text ne $expected) {
			my @got = split /\n/, $text;
			my @expected = split /\n/, $expected;
			is_deeply(\@got, \@expected, "Generated the proper XML for $file");

			# Start the GUI's main loop
			Gtk2->main();
		}
		else {
			ok("XML rendered properly $file");
		}
	}

	return 0;
}


sub expected {
	my ($file) = @_;
	$file .= '.expected';
	my $content = decode('UTF-8', slurp($file));
	chomp ($content);
	return $content;
}
