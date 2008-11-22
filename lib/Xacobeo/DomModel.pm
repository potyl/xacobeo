package Xacobeo::DomModel;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2;

use XML::LibXML;
use Xacobeo::Utils qw(:dom);

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

	my $column = add_text_column($treeview, $NODE_NAME, 'Element');

	# Icon
	my $node_icon = Gtk2::CellRendererPixbuf->new();
	$column->pack_start($node_icon, FALSE);
	$column->set_attributes($node_icon, 'stock-id' => $NODE_ICON);


	# Node attribute name (ID attribute)
	add_text_column($treeview, $NODE_ID_NAME, 'ID name');

	# Node attribute value (ID attribute)
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
	my ($model, $document, $node, $iter) = @_;
	
	# Clear the model if called for the first time (there's no iter defined)
	$model->clear() unless defined $iter;

	# Add the current 'Element' (the first call could be for a 'Document')
	if (isa_dom_element($node)) {
		$iter = $model->append($iter);

		# Find out if an attribute is used as an ID
		foreach my $attribute ($node->attributes) {

			# Keep only the attributes (there could be some namespaces that qualify as attributes)
			next unless isa_dom_attribute($attribute) && $attribute->isId;
			$model->set(
				$iter,
				$NODE_ID_NAME  => $document->get_prefixed_name($attribute),
				$NODE_ID_VALUE => $attribute->value,
			);
			
			# There should be only one ID per element
			last;
		}

		# 
		$model->set(
			$iter,
			$NODE_ICON => 'gtk-directory',
			$NODE_NAME => $document->get_prefixed_name($node),
			$NODE_DATA => $node,
		);
	}
	
	
	# Add the children to the DOM model
	foreach my $child ($node->childNodes) {
		populate($model, $document, $child, $iter) if isa_dom_element($child);
	}
}


# A true value
1;
