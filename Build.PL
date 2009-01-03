#!/usr/bin/perl

use strict;
use warnings;

use inc::MyBuilder;
use File::Spec::Functions;


my %requires = (
	perl => '5.6.1',

	'Pod::Usage'            => 0,
	'Getopt::Long'          => 0,
	'Glib'                  => 0,
	'Gtk2'                  => 0,
	'Gtk2::GladeXML'        => 0,
	'Time::HiRes'           => 0,
	'XML::LibXML'           => 0,
	'Class::Accessor::Fast' => 0,
	'File::Spec::Functions' => 0,
	'FindBin'               => 0,
	'Carp'                  => 0,
	'Exporter'              => 0,
	'DynaLoader'            => 0,
	'Data::Dumper'          => 0,
);


my $build = inc::MyBuilder->new(
	module_name       => 'Xacobeo',
	license           => 'perl',
	dist_author       => 'Emmanuel Rodriguez <potyl@cpan.org>',
	dist_version_from => catfile('lib', 'Xacobeo.pm'),
	
	# Installation files
	script_file => [ catfile('bin', 'xacobeo') ],


	# Dependencies
	requires => \%requires,
	build_requires => {
		'Test::More' => '0',
	},
);


$build->create_build_script();
