package Xacobeo::GObject;

=head1 NAME

Xacobeo::GObject - Build GObjects easily.

=head1 SYNOPSIS

	package My::Widget;
	
	use Xacobeo::GObject 'Gtk2::Entry' =>
		properties => [
			Glib::ParamSpec->object(
				'ui-manager',
				'UI Manager',
				"The UI Manager that provides the UI.",
				'Gtk2::UIManager',
				['readable', 'writable'],
			),
		],
	;
	
	# Builtin constructor
	my $widget = My::Widget->new();
	
	# Set the property and fires the signal 'notify::ui-manager'
	$widget->set_ui_manager(Gtk2::UIManager->new);
	
	# Get the property
	$widget->get_ui_manager;
	
	# Direct accessor/setter (the setter doesn't fire any signal)
	$widget->ui_manager;

=head1 DESCRIPTION

Simple framework for building GObjects. This package is very similar to
C<Glib::Object::Subclass> except this one create accessors and setters for the
object properties.

=cut


use strict;
use warnings;

use Glib;
use Carp;
use Data::Dumper;


sub import {
	my ($self, $parent, %args) = @_;
	my $class = caller;
	$self->register_object($class, $parent, %args);
}


sub register_object {
	croak "Missing a class and parent class" unless @_ > 2;
	my (undef, $class, $parent, %args) = @_;

	Glib::Type->register_object($parent, $class, %args);
	
	# Make the class an instance of Glib::Object
	do {
		no strict 'refs';
		unshift @{ "${class}::ISA" }, 'Glib::Object';
	};

	
	# For each property define a get_/set_ method
	if (my $properties = $args{properties}) {
		foreach my $property (@{ $properties }) {
			
			my $name = $property->{name};
			my $key = $property->get_name;
			
			# The accessor: $value = $self->get_property
			define_method($class, "get_$key", sub {
				return $_[0]->{$key};
			});
			
			# The setter: $self->set_property($value)
			define_method($class, "set_$key", sub {
					$_[0]->set($name, $_[1]);
			});


			# Generic getter/setter which doesn't fire the 'notify' signal:
			#   $value = $self->property;
			#   $self->property($value);
			define_method($class, $key, sub {
					return @_ > 1 ? $_[0]{$key} = $_[1] : $_[0]{$key};
			});
		}
	}
}


sub define_method {
	my ($class, $method, $sub) = @_;
	no strict 'refs';
	*{"${class}::${method}"} = $sub unless $class->can($method);
}


# A true value
1;


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
