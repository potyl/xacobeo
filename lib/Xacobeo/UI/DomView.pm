package Xacobeo::UI::DomView;

=head1 NAME

Xacobeo::UI::DomView - DOM tree view

=head1 SYNOPSIS

	use Xacobeo::DomView;
	use Xacobeo::UI::SourceView;
	
	my $view = Xacobeo::UI::SourceView->new();
	$window->add($view);
	
	# Load a document
	my $document = Xacobeo::Document->new($file, $type);
	$view->set_document($document);
	$view->load_node($document->documentNode);

=head1 DESCRIPTION

The application's main window. This widget is a L<Gtk2::TreeView>.

=head1 METHODS

The following methods are available:

=head2 new

Creates a new instance. This is simply the parent's constructor.

=cut

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;
use Xacobeo::I18n;
use Xacobeo::XS;

use Xacobeo::Accessors qw{
	document
	namespaces
};

use Glib::Object::Subclass 'Gtk2::TreeView' =>
	signals => {
		'node-selected' => {
			flags       => ['run-last'],
			# Parameters:   Node 
			param_types => ['Glib::Scalar'],
		},
	},
;


my $NODE_POS = 0;
my $NODE_PATH     = $NODE_POS++;
my $NODE_ICON     = $NODE_POS++;
my $NODE_NAME     = $NODE_POS++;
my $NODE_ID_NAME  = $NODE_POS++;
my $NODE_ID_VALUE = $NODE_POS++;


sub INIT_INSTANCE {
	my $self = shift;

	my $model = Gtk2::TreeStore->new(
		'Glib::String', # Unique path to the node
		'Glib::String', # The icon to use (ex: 'gtk-directory')
		'Glib::String', # The name of the Element
		'Glib::String', # The name of the ID field
		'Glib::String', # The value of the ID field
	);
	$self->set_model($model);

	my $column = $self->_add_text_column($NODE_NAME, __('Element'));

	# Icon
	my $node_icon = Gtk2::CellRendererPixbuf->new();
	$column->pack_start($node_icon, FALSE);
	$column->set_attributes($node_icon, 'stock-id' => $NODE_ICON);

	# Node attribute name (ID attribute)
	$self->_add_text_column($NODE_ID_NAME, __('ID name'));

	# Node attribute value (ID attribute)
	$self->_add_text_column($NODE_ID_VALUE, __('ID value'));
	

	$self->signal_connect(row_activated => \&callback_row_activated);
}


#
# Transform the signal 'row-activated' into 'node-selected'
#
sub callback_row_activated {
	my ($self, $path) = @_;

	my $model = $self->get_model;
	my $iter = $model->get_iter($path);
	my $xpath = $model->get($iter, $NODE_PATH);

	my $node = $self->document->find($xpath)->[0];
	$self->signal_emit('node-selected' => $node);
}


sub set_document {
	my $self = shift;
	my ($document) = @_;

	$self->document($document);
	$self->namespaces(
		$self->document ? $self->document->namespaces : undef
	);
}

=head2 load_node

Sets the tree view nodes hierarchy based on the given node. This is the method
that will actually add items to the widget.

Parameters:

=over

=item * $node

The node to be loaded into the tree widget; an instance of L<XML::LibXML::Node>.

=back

=cut


sub load_node {
	my $self = shift;
	my ($node) = @_;

	my $store = $self->get_model;

	$self->set_model(undef);
	if (defined $node and defined $store) {
		Xacobeo::XS->load_tree_store($store, $node, $self->namespaces);
	}
	elsif (defined $store) {
		$store->clear();
	}
	$self->set_model($store);

	# Expand the first level
	if (my $iter = $store->get_iter_first) {
		my $path = $store->get_path($iter);
		$self->expand_row($path, FALSE);
	}
}


#
# Adds a text column to the tree view
#
sub _add_text_column {
	my $self = shift;
	my ($field, $title) = @_;

	my $cell = Gtk2::CellRendererText->new();
	my $column = Gtk2::TreeViewColumn->new();
	$column->pack_end($cell, TRUE);

	$column->set_title($title);
	$column->set_resizable(TRUE);
	$column->set_sizing('autosize');
	$column->set_attributes($cell, text => $field);

	$self->append_column($column);

	return $column;
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

