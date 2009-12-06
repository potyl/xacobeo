package Xacobeo::UI::DomView;

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;
use Xacobeo::I18n;
use Xacobeo::XS;

use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		document
		namespaces
	)
);

use Glib::Object::Subclass 'Gtk2::TreeView';


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
}


sub set_document {
	my $self = shift;
	my ($document) = @_;

	$self->document($document);
	$self->namespaces(
		$self->document ? $self->document->namespaces : undef
	);
}


sub show_node {
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


1;
