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


sub ACTION_install {
	my $self = shift;

	# Make sure that share/ has an installation path
	my $p = $self->{properties};
	if (! exists $p->{install_path}{share}) {
		my $script_dir = $self->install_destination('script');
		my @dirs = File::Spec->splitdir($script_dir);
		$dirs[-1] = 'share';
		$p->{install_path}{share} = File::Spec->catdir(@dirs);
	}

	# Proceed normally
	$self->SUPER::ACTION_install(@_);
}


sub ACTION_post_install {
	my $self = shift;
	print "Updating desktop database\n";
	system('update-desktop-database');
}


sub ACTION_build {
	my $self = shift;

	# Copy the files in share/
	for my $entry (@{ $self->rscan_dir('share') }) {

		# Skip hidden entries or folders
		next if $entry =~ m,(^|/)\., or -d $entry;

		$self->copy_if_modified(
			from => $entry,
			to   => catfile($self->blib, $entry) 
		);
	}

	# Proceed normally
	$self->SUPER::ACTION_build(@_);
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
	'Class::Accessor::Fast' => 0,
	'File::Spec::Functions' => 0,
	'FindBin'               => 0,
	'Carp'                  => 0,
);


my $build = $class->new(
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
