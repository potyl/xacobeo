#!/usr/bin/perl

package Xacobeo::Simple;

use strict;
use warnings;

use Xacobeo::XS;

use XML::LibXML;
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Pango;


sub render_document {
	my ($filename) = @_;

	# Register new text buffers with support syntaxt highlighting
	my ($textview, $treeview) = create_widgets();
	my $tag_table = create_xml_tag_table();
	my $buffer = Gtk2::TextBuffer->new($tag_table);
	$textview->set_buffer($buffer);

	# Parse the document
	my $document = parse_document($filename);
	my $namespaces = get_namespaces($document);
	
	# Show the document with syntax highlighting
	Xacobeo::XS::populate_textview($textview, $document, $namespaces);
	Xacobeo::XS::populate_treeview($treeview, $document, $namespaces);
	
	return ($textview, $document, $namespaces);
}


sub create_widgets {
	my $window = Gtk2::Window->new('toplevel');
	
	my $textview = create_textview();
	my $treeview = create_treeview();


	# Pack the widgets together
	my $paned = Gtk2::HPaned->new();
	$paned->set_position(200);
	$paned->add1(wrap_in_scrolls($treeview));
	$paned->add2(wrap_in_scrolls($textview));
	$window->add($paned);
	$window->show_all();
	
	$window->signal_connect(destroy => sub {Gtk2->main_quit();});
	
	
	return ($textview, $treeview);
}


sub create_textview {
	my $textview = Gtk2::TextView->new();
	$textview->set_size_request(600, 400);
	$textview->set_editable(FALSE);
	$textview->set_cursor_visible(FALSE);
	return $textview;
}


sub create_treeview {
	# Prepre the tree view
	my $treeview = Gtk2::TreeView->new();
	my $store = Gtk2::TreeStore->new(
		'Glib::Scalar',
		'Glib::String',
	);
	$treeview->set_model($store);

	$treeview->signal_connect(row_activated =>
		sub {
			my ($treeview, $path, $column) = @_;
#			# The C code creates a new model
#			my $model = $treeview->get_model;
			my $iter = $store->get_iter($path);
			my $node = $store->get($iter, 0);

			print "Node is ", $node->toString, "\n";
		}
	);

	my $cell = Gtk2::CellRendererText->new();
	my $column = Gtk2::TreeViewColumn->new_with_attributes(
		"Element", $cell,
		'text' => 1,
#		'resizable' => TRUE,
#		'autosize'  => TRUE,
	);
  $treeview->insert_column($column, 0);

	return $treeview;
}


sub wrap_in_scrolls {
	my ($widget) = @_;

	my $scrolls = Gtk2::ScrolledWindow->new(undef, undef);
	$scrolls->set_policy('automatic', 'always');
	$scrolls->set_shadow_type('out');
	$scrolls->add($widget);

	return $scrolls;
}


#
# This function creates the tag table to be used by all text buffers displaying
# XML.
#
sub create_xml_tag_table {
	# Build the styles for the syntax highlighting
	my $tag_table = Gtk2::TextTagTable->new();
	
	local $_ = $tag_table;
	# This closure looks ugly but it's purpose is to enable us to copy/paste the C
	# code used to create the tags without any modification. Because the closure
	# is named perl will issue a warning if $tag_table is accessed directly. A
	# local copy ($_) is used instead.
	sub TAG {add_tag($_, @_);};
	use constant PANGO_STYLE_ITALIC => 'italic';
	

	TAG("result_count", 
		"family",      "Courier 10 Pitch",
		"background",  "#EDE9E3",
		"foreground",  "black",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("boolean", 
			"family",      "Courier 10 Pitch",
			"foreground",  "black",
			"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("number", 
			"family",      "Courier 10 Pitch",
			"foreground",  "black",
			"weight",      PANGO_WEIGHT_BOLD
	);

	TAG("attribute_name", 
		"foreground",  "red"
	);

	TAG("attribute_value", 
		"foreground",  "blue"
	);
	
	TAG("comment", 
		"foreground",  "#008000",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("dtd", 
		"foreground",  "#558CBA",
		"style",       PANGO_STYLE_ITALIC
	);
	
	TAG("element", 
		"foreground",  "#800080",
		"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("pi", 
		"foreground",  "#558CBA",
		"style",       PANGO_STYLE_ITALIC
	);
	
	TAG("pi_data", 
		"foreground",  "red",
		"style",       PANGO_STYLE_ITALIC
	);
	
	TAG("syntax", 
		"foreground",  "black",
		"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("text", 
		"foreground",  "black"
	);
	
	TAG("literal", 
		"foreground",  "black"
	);
	
	TAG("cdata", 
		"foreground",  "red",
		"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("cdata_content", 
		"foreground",  "purple",
		"weight",      PANGO_WEIGHT_BOLD,
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("namespace_name", 
		"foreground",  "red",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("namespace_uri", 
		"foreground",  "blue",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("entity_ref", 
		"foreground",  "red",
		"weight",      PANGO_WEIGHT_BOLD
	);

	return $tag_table;
}


#
# Creates a text tag (Gtk2::TextTag) with the given name and properties and adds
# it to a tag table.
#
sub add_tag {
	my ($tag_table, $name, @properties) = @_;
	my $tag = Gtk2::TextTag->new($name);
	$tag->set(@properties);
	$tag_table->add($tag);
}


#
# Parse the XML document.
#
sub parse_document {
	my ($filename) = @_;
	my $parser = XML::LibXML->new();
	$parser->line_numbers(1);
	$parser->recover_silently(1);
	$parser->complete_attributes(0);
	$parser->expand_entities(0);

	my $document = $parser->parse_file($filename);
	return $document;
}


#
# Get the namespaces declared in the document.
#
sub get_namespaces {
	my ($document) = @_;
	my %namespaces = ();
	foreach my $namespace ($document->findnodes('.//namespace::*')) {
		my $uri = $namespace->getData;
		$namespaces{$uri} ||= $namespace->getLocalName;
	}
	
	# Reverse the namespaces ($prefix -> $uri) and make sure that the prefixes
	# don't clash with each other.
	my $cleaned = {};
	my $namespaces = {};
	my $index = 0;
	while (my ($uri, $prefix) = each %namespaces) {

		# Make sure that the prefixes are unique
		if (! defined $prefix or exists $cleaned->{$prefix}) {
			# Assign a new prefix until unique
			do {
				$prefix = 'default' . ($index ? $index : '');
				++$index;
			} while (exists $cleaned->{$prefix});
		}
		$cleaned->{$prefix} = $uri;
		$namespaces->{$uri} = $prefix;
	}
	return $namespaces;
}


# Return a true value
1;
