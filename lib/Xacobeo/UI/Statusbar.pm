package Xacobeo::UI::Statusbar;

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;


use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		context_id
	)
);

use Glib::Object::Subclass 'Gtk2::Statusbar';


sub INIT_INSTANCE {
	my $self = shift;

	$self->context_id(
		$self->get_context_id('default')
	);
}


sub display {
	my $self = shift;
	my ($message) = @_;

	my $id = $self->context_id;
	$self->pop($id);
	$self->push($id, $message);
}


sub displayf {
	my $self = shift;
	my ($format, @args) = @_;
	
	$self->display(sprintf $format, @args);
}


1;
