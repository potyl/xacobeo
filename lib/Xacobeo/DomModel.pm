package Xacobeo::DomModel;

=encoding utf8

=head1 NAME

Xacobeo::DomModel - The DOM model used for the TreeView.

=head1 SYNOPSIS

	use Xacobeo::Document;
	use Xacobeo::UI;
	use Gtk2;
	
	# Create the view
	my $treeview = Gtk2::TreeView->new();
	
	# Create the model and link it with the view
	Xacobeo::DomModel::create_model_with_view(
		$treeview,
		sub {
			my ($node) = @_;
			print "Selected node ", $node->toString(), "\n";
		},
	);

=head1 DESCRIPTION

This package provides a way for creating and populating a standard
L<Gtk2::TreeStore>. Take note that this package is not a L<Gtk2::TreeStore>, it
only provides helper functions in order to manipulate one.

=head1 FUNCTIONS

The package defines the following functions:

=cut

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2;

use XML::LibXML;
use Xacobeo::Utils qw(:dom);
use Xacobeo::I18n qw(__);

use Data::Dumper;

my $NODE_POS = 0;
my $NODE_DATA     = $NODE_POS++;
my $NODE_ICON     = $NODE_POS++;
my $NODE_NAME     = $NODE_POS++;
my $NODE_ID_NAME  = $NODE_POS++;
my $NODE_ID_VALUE = $NODE_POS++;


#
# See http://scentric.net/tutorial/sec-custom-models.html
# This page shows how to implement a custom Tree Model.
#


=head2 create_model_with_view

Creates a new TreeModel and links it with the given TreeView. The view will have
the columns of the data types added and the I<row-activated> callback set with a
wrapper that will invoque the callback I<$on_click>.

The user provided callback I<$on_click> will be invoked each time that a node is
double clicked. This callback takes a single argument the L<XML::LibXML::Node>
that has been selected.

Parameters:

=over

=item * $treeview

A reference to the L<Gtk2::TreeView> that will be linked with the
L<Gtk2::TreeStore>.

=item * $on_click

A callback that will invoked each time that a node is selected. The callback is
in the fashion:

	sub callback {
		my ($node) = @_;
		$node->isa('XML::LibXML::Node');
	}

=back

=cut

sub create_model_with_view {
	my ($treeview, $on_click) = @_;

	my $model = Gtk2::TreeStore->new(
		'Glib::Scalar', # A reference to the XML::LibXML::Element
		'Glib::String', # The icon to use (ex: 'gtk-directory')
		'Glib::String', # The name of the Element
		'Glib::String', # The name of the ID field
		'Glib::String', # The value of the ID field
	);

	$treeview->set_model($model);
	$treeview->signal_connect(row_activated =>
		sub {
			my ($treeview, $path, $column) = @_;
			my $iter = $model->get_iter($path);
			my $node = $model->get($iter, $NODE_DATA);

			$on_click->($node);
		}
	);

	add_columns($treeview);

	return $model;
}



#
# Adds the columns to the DOM tree view
#
sub add_columns {
	# Arguments
	my ($treeview) = @_;

	my $column = add_text_column($treeview, $NODE_NAME, __('Element'));

	# Icon
	my $node_icon = Gtk2::CellRendererPixbuf->new();
	$column->pack_start($node_icon, FALSE);
	$column->set_attributes($node_icon, 'stock-id' => $NODE_ICON);


	# Node attribute name (ID attribute)
	add_text_column($treeview, $NODE_ID_NAME, __('ID name'));

	# Node attribute value (ID attribute)
	add_text_column($treeview, $NODE_ID_VALUE, __('ID value'));

	return;
}



#
# Adds a text column to the tree view
#
sub add_text_column {
	my ($treeview, $field, $title) = @_;

	my $cell = Gtk2::CellRendererText->new();
	my $column = Gtk2::TreeViewColumn->new();
	$column->pack_end($cell, TRUE);

	$column->set_title($title);
	$column->set_resizable(TRUE);
	$column->set_sizing('autosize');
	$column->set_attributes($cell, text => $field);

	$treeview->append_column($column);

	return $column;
}


# A true value
1;


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
