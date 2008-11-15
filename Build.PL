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
	# define install path for share data and call parent
	my $self = shift;
	my $p = $self->{properties};
print ">>ACTION_install\n";
	unless (
		exists $p->{install_path}{share}
		or $p->{install_base}
	) {
print ">>in confidition\n";
		my $bindir = $self->install_destination('script');
		my @dirs = File::Spec->splitdir($bindir);
		pop @dirs; # 'bin'
		my $sharedir = File::Spec->catdir(@dirs, 'share');
		$p->{install_path}{share} = $sharedir;
	}

	$self->SUPER::ACTION_install(@_);

	print "Trying to run 'update-desktop-database' ... ";
	print system('update-desktop-database') ? "Failed\n" : "Ok\n";
}

sub ACTION_build {
	# copy share data and call parent
	my $self = shift;
	$self->{properties}{script_files} = ['bin/xacobeo']; # Bug in M:B ?

#	$self->do_system($self->perl, './Config.PL');
#	$self->do_system($self->perl, './Lingua.PL');
	$self->_build_share;

	$self->SUPER::ACTION_build(@_)
}

sub _build_share {
	my $self = shift;
	my $blib = $self->blib;
	for (@{$self->rscan_dir('share')}) {
		next if m{^\.|[/\\\\]\.|Development} or -d $_;
		my $to = $_;
		$self->copy_if_modified(
			from => $_,
			to   => File::Spec->catfile($blib, $to) );
	}
}

sub install_base_relative { # define install base path for share data
	my ($self, $type) = @_;
	return 'share' if $type eq 'share';
	return 'bin' if $type eq 'script';
	$self->SUPER::install_base_relative($type);
}



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
	'Class::Accessor::Fast' => 0,
	'File::Spec::Functions' => 0,
	'FindBin'               => 0,
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

#$build->add_build_element('share');
#$build->install_base_relpaths(share => 'share');

$build->create_build_script();
