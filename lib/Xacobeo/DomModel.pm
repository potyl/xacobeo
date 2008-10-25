package Xacobeo::DomModel;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2;

use XML::LibXML;

use Data::Dumper;

my $NODE_POS = 0;
our $NODE_DATA    = $NODE_POS++;
my $NODE_ICON     = $NODE_POS++;
my $NODE_NAME     = $NODE_POS++;
my $NODE_ID_NAME  = $NODE_POS++;
my $NODE_ID_VALUE = $NODE_POS++;


#
# See http://scentric.net/tutorial/sec-custom-models.html
# This page shows how to implement a custom Tree Model.
#


#
# Creates the model object used to represent the DOM tree
#
sub create_model {

	my $model = Gtk2::TreeStore->new(
		qw(
			Glib::Scalar
			Glib::String
			Glib::String
			Glib::String
			Glib::String
		)
	);
	
	return $model;
}


#
# Adds the columns to the DOM tree view
#
sub add_columns {
	# Arguments
	my ($treeview) = @_;

if (0) {
	## Add the first column - Node element
	my $column = Gtk2::TreeViewColumn->new();
	$column->set_title('DOM');
	$column->set_resizable(TRUE);
	$column->set_sizing('autosize');

	### First cell for column one - Icon
	my $node_icon = Gtk2::CellRendererPixbuf->new();
	$column->pack_start($node_icon, FALSE);
	$column->set_attributes($node_icon, 'stock-id' => $NODE_ICON);

	### Second cell for column one - Name
	my $node_name = Gtk2::CellRendererText->new();
	$column->pack_start($node_name, FALSE);
	$column->set_attributes($node_name, 'text' => $NODE_NAME);
	$treeview->append_column($column);
}
	my $column = add_text_column($treeview, $NODE_NAME, 'Element');
	### First cell for column one - Icon
	my $node_icon = Gtk2::CellRendererPixbuf->new();
	$column->pack_start($node_icon, FALSE);
	$column->set_attributes($node_icon, 'stock-id' => $NODE_ICON);
	



	## Add the second column - Node attribute name (ID attribute)
	add_text_column($treeview, $NODE_ID_NAME, 'ID name');

	## Add the third column - Node attribute value (ID attribute)
	add_text_column($treeview, $NODE_ID_VALUE, 'ID value');
}

sub add_text_column {
	my ($treeview, $field, $title) = @_;
	
	my $column = Gtk2::TreeViewColumn->new();
	$column->set_title($title);
	$column->set_resizable(TRUE);
	$column->set_sizing('autosize');

	my $cell = Gtk2::CellRendererText->new();
	$column->pack_end($cell, TRUE);
	$column->set_attributes($cell, 'text' => $field);
	$treeview->append_column($column);
	
	return $column;
}


#
# Populates the DOM tree model by adding only node of the type 'Element'.
#
sub populate {
	my ($model, $node, $namespaces, $iter) = @_;
	
	# Clear the model if called for the first time (there's no iter defined)
	$model->clear() unless defined $iter;

	# Add the current 'Element' (the first call could be for a 'Document')
	if ($node->isa('XML::LibXML::Element')) {
		$iter = $model->append($iter);

		# Find out if an attribute is used as an ID
		foreach my $attribute ($node->attributes) {

			# Keep only the attributes (there could be some namespaces that qualify as attributes)
			next unless $attribute->isa('XML::LibXML::Attr') && $attribute->isId;
			$model->set(
				$iter,
				$NODE_ID_NAME  => get_prefixed_name($attribute, $namespaces),
				$NODE_ID_VALUE => $attribute->value,
			);
			
			# There should be only one ID per element
			last;
		}

		# 
		$model->set(
			$iter,
			$NODE_ICON => 'gtk-directory',
			$NODE_NAME => get_prefixed_name($node, $namespaces),
			$NODE_DATA => $node,
		);
	}
	
	
	# Add the children to the DOM model
	foreach my $child ($node->childNodes) {
		populate($model, $child, $namespaces, $iter) if $child->isa('XML::LibXML::Element');
	}
}


#
# Returns the node name by prefixing it with our prefixes in the case where
# namespaces are used.
#
sub get_prefixed_name {

	my ($node, $namespaces) = @_;

	my $name = $node->localname;
	my $uri = $node->namespaceURI();
	
	# Check if the node uses a namespace if so return the name with our prefix
	if (defined $uri and my $namespace = $namespaces->{$uri}) {
		return "$namespace:$name";
	}

	return $name;
}


# A true value
1;
