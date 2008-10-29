#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;
use File::Spec;

my %requires = (
	perl => '5.6.1',

	'Pod::Usage'            => 0,
	'Getopt::Long'          => 0,
	'Glib'                  => 0,
	'Gtk2'                  => 0,
	'Gtk2::GladeXML'        => 0,
	'Time::HiRes'           => 0,
	'XML::LibXML'           => 0,
	'File::ShareDir'        => 0,
	'Class::Accessor::Fast' => 0,
);


my $build = Module::Build->new(
	module_name       => 'Xacobeo',
	license           => 'perl',
	dist_author       => 'Emmanuel Rodriguez <potyl@cpan.org>',
	dist_version_from => 'bin/xacobeo',
	
	# Installation files
	script_file => ['bin/xacobeo'],
	share_files => {
		'share/xacobeo.glade' => 'share/xacobeo.glade',
	},


	# Dependencies
	requires => \%requires,
	build_requires => {
		'Test::More' => '0',
	},
);

$build->add_build_element('share');
$build->install_base_relpaths(share => 'share');

$build->create_build_script();
