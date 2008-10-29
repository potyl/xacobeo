#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;
use File::Spec::Functions;


my $class = Module::Build->subclass(
	class => 'Xacobeo::Builder',
	code  => q{

use warnings;
use strict;

use File::Spec::Functions;


sub process_share_files {
	my $self = shift;
	my $blib = $self->blib;

	# Copy the files in share/
	for my $entry (@{ $self->rscan_dir('share') }) {
		# Skip hidden entries or folders
		next if $entry =~ m,(^|/)\., or -d $entry;

		$self->copy_if_modified(
			from => $entry,
			to   => catfile($blib, $entry) 
		);
	}
}

});



my %requires = (
	perl => '5.6.1',

	'Pod::Usage'            => 0,
	'Getopt::Long'          => 0,
	'Glib'                  => 0,
	'Gtk2'                  => 0,
	'Gtk2::GladeXML'        => 0,
	'Time::HiRes'           => 0,
	'XML::LibXML'           => 0,
# Remove this as all data will be in the folder $PREFIX/share/xacobeo
	'File::ShareDir'        => 0,
	'Class::Accessor::Fast' => 0,
);


my $build = $class->new(
	module_name       => 'Xacobeo',
	license           => 'perl',
	dist_author       => 'Emmanuel Rodriguez <potyl@cpan.org>',
	dist_version_from => catfile('bin', 'xacobeo'),
	
	# Installation files
	script_file => [ catfile('bin', 'xacobeo') ],


	# Dependencies
	requires => \%requires,
	build_requires => {
		'Test::More' => '0',
	},
);

$build->add_build_element('share');
$build->install_base_relpaths(share => 'share');

$build->create_build_script();
