package Xacobeo::Conf;

use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		dir
	)
);


my $INSTANCE = __PACKAGE__->init();


sub get_conf {
	return $INSTANCE;
}


sub init {
	my $class = shift;
	my ($dir) = @_;
	
	$dir ||= find_app_folder();

	my $self = bless {}, ref($class) || $class;
	$self->dir($dir);
	
	$INSTANCE = $self;
}


sub share_dir {
	my $self = shift;
	return catdir($self->dir, 'share', @_); 
}


sub share_file {
	my $self = shift;
	return catfile($self->dir, 'share', @_); 
}


sub app_name {
	return "Xacobeo";
}


# Return the root folder of the application once installed. The 'root' folder is
# the one where the installation is done, the root folder hierarchy is as
# follows:
#
# (root)
# |-- bin
# |-- lib
# |   `-- perl5
# |       |-- Xacobeo
# |       `-- i486-linux-gnu-thread-multi
# |               `-- Xacobeo
# |           `-- auto
# |               `-- Xacobeo
# |-- man
# |   |-- man1
# |   `-- man3
# `-- share
#     |-- applications
#     |-- pixmaps
#     `-- xacobeo
sub find_app_folder {
	return catdir($FindBin::Bin, '..');
}

1;
