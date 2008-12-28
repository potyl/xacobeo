package Xacobeo::UI;

=head1 NAME

Xacobeo::UI - The graphical interface of the application.

=head1 SYNOPSIS

	use Xacobeo::UI;
	
=head1 DESCRIPTION

This package provides the graphical user interface (GUI) of the application.
Most of the GUI is made through Glade and this package provides the callbacks
and the application logic.

=head1 METHODS

The package defines the following methods:

=cut

use strict;
use warnings;


use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::GladeXML;
use Gtk2::SimpleList;
use Gtk2::Pango;

use Data::Dumper;
use Carp;
use File::Spec::Functions;

use Xacobeo::DomModel;
use Xacobeo::Document;
use Xacobeo::Utils qw(:xml :dom);
use Xacobeo::Timer;
use Xacobeo::XS qw(
	xacobeo_populate_gtk_text_buffer
	xacobeo_populate_gtk_tree_store
);


use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		glade
		document 
		statusbar_context_id
		namespaces_view
		xpath_markup
		app_folder
	)
);


my $APP_NAME = 'Xacobeo';


=head2 new

Constructor. Creates a new instance of the UI.

Parameters:

=over

=item * $app_folder

The application's root folder.

=back	

=cut

sub new {
	# Arguments
	my $class = shift;
	croak 'Usage: new($app_folder)' unless @_;
	my ($app_folder) = @_;
	
	# Create an instance
	my $self = bless {}, ref($class) || $class;
	
	# Create the GUI
	$self->app_folder($app_folder);
	$self->construct_gui();
	
	# Return the new instances
	return $self;
}


#
# This method constructs the GUI
#
sub construct_gui {
	# Arguments
	my $self = shift;

	my $folder = $self->app_folder();
	
	# Load the GUI definition from the glade files
	my $glade = Gtk2::GladeXML->new(catfile($folder, 'share', 'xacobeo', 'xacobeo.glade'));
	$self->glade($glade);
	
	my $window = $self->glade->get_widget('window');
	$window->set_title($APP_NAME);

	# Set the application's icon
	my $logo = Gtk2::Gdk::Pixbuf->new_from_file(catfile($folder, 'share', 'pixmaps', 'xacobeo.png'));
	$window->set_icon($logo);
	$self->glade->get_widget('about')->set_logo($logo);



	# Connect the signals to the callbacks
	$glade->signal_autoconnect_from_package($self);
	
	# Status bar context id
	my $statusbar = $self->glade->get_widget('statusbar');
	$self->statusbar_context_id(
		$statusbar->get_context_id('xpath-results')
	);
	
	# Create the tree model for the DOM view
	# See http://www.mail-archive.com/gtk-perl-list@gnome.org/msg03647.html	
	# and http://gtk2-perl.sourceforge.net/doc/pod/Gtk2/TreeViewColumn.html#_tree_column_set_cel
	$self->construct_dom_tree_view();
	
	$self->prepare_textviews();
	
	# Create the list model for the Namespace view
	$self->construct_namespaces_view();
}



#
# Creates the DOM tree view
#
sub construct_dom_tree_view {
	# Arguments
	my $self = shift;

	# Create the view
	my $treeview = $self->glade->get_widget('dom-tree-view');

	# Create the model and link it with the view
	Xacobeo::DomModel::create_model_with_view(
		$treeview,	
		sub {
			my ($node) = @_;
			# Display the node in results text view. Temporary hack, in the future
			# clicking on the node will display the node finition in the sourve view.
			$self->display_results($node);
		},
	);
}


#
# Displays an XML node into a text view. This mehtod clears the view of it's old
# content before displaying the new data.
#
sub display_xml_node {
	my $self = shift;
	my ($widget_name, $node) = @_;
	
	my $namespaces = $self->document->namespaces;
	my $textview = $self->glade->get_widget($widget_name);

	# It's faster to disconnect the buffer from the view and to reconnect it back
	my $buffer = $textview->get_buffer;
	$textview->set_buffer(Gtk2::TextBuffer->new());# Perl-Gk2 Bug can't set undef as a buffer
	
	# Clear the buffer
	$buffer->delete($buffer->get_start_iter, $buffer->get_end_iter);


	# A NodeList
	if (isa_dom_nodelist($node)) {
		my @children = $node->get_nodelist;
		my $count = scalar @children;

		# Formatting using to indicate which result is being analyzed
		my $i = 0;
		my $format = sprintf " %%%dd. ", length($count);

		foreach my $child (@children) {
			# Add the result count
			my $result = sprintf $format, ++$i;
			buffer_add($buffer, result_count => $result);
			
			if (isa_dom_namespace($child)) {
				# The namespaces nodes are an invention of XML::LibXML and they don't
				# work with the XS code, we deal with them manually
				buffer_add($buffer, syntax => ' ');
				buffer_add($buffer, namespace_name => $child->nodeName);
				buffer_add($buffer, syntax => '="');
		
				my $uri = escape_xml_attribute($child->getData);
				buffer_add($buffer, namespace_uri => $uri);
		
				buffer_add($buffer, syntax => '"');
			}
			else {
				# Performed through XS
				xacobeo_populate_gtk_text_buffer($buffer, $child, $namespaces);
			}
			
			buffer_add($buffer, syntax => "\n") if --$count;
		}
	}

	# A Boolean value ex: true() or false()
	elsif (isa_dom_boolean($node)) {
		buffer_add($buffer, boolean => $node->to_literal);
	}

	# A Number ex: 2 + 5
	elsif (isa_dom_number($node)) {
		buffer_add($buffer, number => $node->to_literal);
	}

	# A Literal (a single text string) ex: "hello"
	elsif (isa_dom_literal($node)) {
		buffer_add($buffer, literal => $node->to_literal);
	}

	else {
		# Any kind of XML node (XS call)
		xacobeo_populate_gtk_text_buffer($buffer, $node, $namespaces);
	}


	# Add the buffer back into into the text view
	$textview->set_buffer($buffer);

	# Scroll to tbe beginning
	$textview->scroll_to_iter($buffer->get_start_iter, 0.0, FALSE, 0.0, 0.0);
}



#
# Displays an XML node in the results text view and makes sure that the results
# view is shown. This mehtod clears the view of it's old content.
#
sub display_results {
	my $self = shift;
	my ($node) = @_;
	
	$self->display_xml_node('xpath-results', $node);
	$self->glade->get_widget('notebook')->set_current_page(0);
}


#
# Creates the Namespaces view
#
sub construct_namespaces_view {
	# Arguments
	my $self = shift;

	my $treeview = $self->glade->get_widget('namepsaces-view');
	my $namespaces_view = Gtk2::SimpleList->new_from_treeview(
		$treeview,
		'Prefix' => 'text',
		'URI'    => 'text',
	);
	
	
	# Try to get a handle on the celleditor for the namespaces
	$namespaces_view->set_column_editable(0, TRUE);
	my ($editor) = $namespaces_view->get_column(0)->get_cell_renderers();
	$editor->signal_connect(edited => 
		sub {
			my ($cell, $text_path, $new_text) = @_;
			printf "New text $text_path $new_text\n";
			my $path = Gtk2::TreePath->new_from_string($text_path);
			#my $iter = $namespaces_view->get_iter($path);
			#$namespaces_view->set($iter, 0, $new_text);
			printf "OLD[$text_path]  %s of $new_text\n", @{ $namespaces_view->{data}[$text_path] };
			return FALSE;
		}
	);
	
	$self->namespaces_view($namespaces_view);
}


=head2 load_file

This method loads a new file into the GUI. The new document will be parsed and
displayed in the window.

Parameters:

=over

=item * $file

The XML file to load.

=back	

=cut

sub load_file { 
	# Arguments
	my $self = shift;
	my ($file) = @_;
	
	# Parse the content
	my $timer = Xacobeo::Timer->start();
	
	my $t_load = Xacobeo::Timer->start('Load document');
	my $document = Xacobeo::Document->new($file);
	$self->document($document);
	undef $t_load;

	my $glade = $self->glade;
	$glade->get_widget('window')->set_title("$APP_NAME - $file");

	my $xml = $document->xml;
	my $namespaces = $document->namespaces;

	# Update the text widget
	my $t_syntax = Xacobeo::Timer->start('Syntax Highlight');
	$self->display_xml_node('xml-document', $xml);
	undef $t_syntax;

	# Populate the DOM view tree
	my $t_dom = Xacobeo::Timer->start('DOM Tree');
	$self->populate_treeview($xml);
	undef $t_dom;
	$timer->stop();
	
	
	# Populate the Namespaces view
	my @namespaces = ();
	while (my ($uri, $prefix) = each %{ $namespaces }) {
		push @namespaces, [$prefix, $uri];
	}
	@{ $self->namespaces_view->{data} } = @namespaces;

	$self->display_statusbar_message(
		sprintf "Document loaded in %.3f s", $timer->elapsed
	);
	
	$glade->get_widget('xpath-entry')->set_sensitive(TRUE);
}



#
# Populates the DOM tree view.
#
sub populate_treeview {
	my $self = shift;
	my ($node) = @_;


	my $treeview = $self->glade->get_widget('dom-tree-view');
	my $store = $treeview->get_model;
	
	$treeview->set_model(undef);
	xacobeo_populate_gtk_tree_store($store, $node, $self->document->namespaces);
	$treeview->set_model($store);
}




=head2 set_xpath

This method sets the XPath expression to display in the XPath text area. The
expression is not evaluated.

Parameters:

=over

=item * $xpath

The XML file to load.

=back	

=cut

sub set_xpath {
	my $self = shift;
	croak 'Usage: $xacobeo->set_xpath($xpath)' unless @_;
	my ($xpath) = @_;
	
	if (defined $xpath) {
		$self->glade->get_widget('xpath-entry')->set_text($xpath);
	}
}


#
# This widget prepares the text view widgets. It basically performs actions that
# can be done through glade. For the moment this method registers some tags used
# for syntax highlighting.
#
sub prepare_textviews {
	my $self = shift;
	
	# Build the styles for the syntax highlighting
	my $tag_table = Gtk2::TextTagTable->new();
	
	add_tag($tag_table, result_count =>
		family     => 'Courier 10 Pitch',
		background => '#EDE9E3',
		foreground => 'black',
		style      => 'italic',,
		weight     => PANGO_WEIGHT_LIGHT
	);
	
	# Make the boolean and number look a like
	foreach my $name qw(boolean number) {
		add_tag($tag_table, $name =>
			family     => 'Courier 10 Pitch',
			foreground => 'black',
			weight     => PANGO_WEIGHT_BOLD
		);
	}
	
	add_tag($tag_table, attribute_name =>
		foreground => 'red',
	);

	add_tag($tag_table, attribute_value =>
		foreground => 'blue',
	);
	
	add_tag($tag_table, comment =>
		foreground => '#008000',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT,
	);
	
	add_tag($tag_table, dtd =>
		foreground => '#558CBA',
		style      => 'italic',
	);
	
	add_tag($tag_table, element =>
		foreground => '#800080',
		weight     => PANGO_WEIGHT_BOLD,
	);
	
	add_tag($tag_table, pi =>
		foreground => '#558CBA',
		style      => 'italic',
	);
	
	add_tag($tag_table, pi_data =>
		foreground => 'red',
		style      => 'italic',
	);
	
	add_tag($tag_table, syntax =>
		foreground => 'black',
		weight     => PANGO_WEIGHT_BOLD,
	);
	
	add_tag($tag_table, literal =>
		foreground => 'black',
	);
	
	add_tag($tag_table, cdata =>
		foreground => 'red',
		weight     => PANGO_WEIGHT_BOLD
	);
	
	add_tag($tag_table, cdata_content =>
		foreground => 'purple',
		weight     => PANGO_WEIGHT_LIGHT,
		style      => 'italic',
	);
	
	add_tag($tag_table, namespace_name =>
		foreground => 'red',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT,
	);
	
	add_tag($tag_table, namespace_uri =>
		foreground => 'blue',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT,
	);
	
	add_tag($tag_table, entity_ref =>
		foreground => 'red',
		style      => 'italic',
		weight     => PANGO_WEIGHT_BOLD,
	);


	# Register new text buffers with support syntaxt highlighting
	foreach my $name qw(xml-document xpath-results) {
		my $buffer = Gtk2::TextBuffer->new($tag_table);
		my $textview = $self->glade->get_widget($name);
		$textview->set_buffer($buffer);
	}
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
# Adds the given text at the end of the buffer. The text is added with a tag
# which can be used for performing syntax highlighting.
#
sub buffer_add {
	my ($buffer, $tag, $string) = @_;
	$buffer->insert_with_tags_by_name($buffer->get_end_iter, $string, $tag);
}


#
# Called when the main window is closed
#
sub callback_window_close {
	Gtk2->main_quit;
}


#
# Called when the XPath expression must be runned.
#
sub callback_run_xpath {
	# Arguments
	my $self = shift;
	
	my $glade = $self->glade;

	my $button = $glade->get_widget('xpath-evaluate');
	return unless $button->is_sensitive;
	
	# Run the XPath expression
	my $xpath = $glade->get_widget('xpath-entry')->get_text;
	my $timer = Xacobeo::Timer->start();
	my $result = $self->document->find($xpath);
	$timer->stop();
	
	my $count = isa_dom_nodelist($result) ? $result->size : 1;
	$self->display_statusbar_message(
		sprintf "Found %d results in %0.3f s", $count, $timer->elapsed
	);
	
	# Display the results
	$self->display_results($result);
}


#
# Called when the XPath expression is changed, this will validate the expression.
#
# NOTE: There's no XPath compiler available, as a hack the XPath expression will
#       be runned againsts an empty document, this way the result will be 
#       instantaneous. Although, a better alternative will be to find a real 
#       XPath parser that can tell where the problem is.
#
sub callback_xpath_entry_changed {
	# Arguments
	my $self = shift;
	my ($widget) = @_;
	
	my $xpath = $widget->get_text;
	my $button = $self->glade->get_widget('xpath-evaluate');
	
	# Pango markup is like XML so we need to escape it
	my $markup = escape_xml_text($xpath);

	# Validate the XPath expression
	if (! $self->document->validate($xpath) ) {
		# Disable the evaluate button and set the XPath expression in red
		$button->set_sensitive(FALSE);

		# Apply the Pango markup to mark the errors in the text
		$markup = "<span underline='error' underline_color='red'>$markup</span>";
	}
	else {
		# The expression is valid, let's restore the widgets to their inital state
		$button->set_sensitive(TRUE);
	}

	$self->xpath_markup($markup);

	# Force a redraw
	if ($widget->realized) {
		my $size = $widget->allocation;
		my $rectangle = Gtk2::Gdk::Rectangle->new(0, 0, $size->width, $size->height);
		$widget->window->invalidate_rect($rectangle, TRUE);
	}
}


# Called at each expose event (redrawing), this happens a lot because of the
# cursor which blinks periodically. The markup is sometimes forgotten between
# redraws. This callback corrects this problem.
sub callback_xpath_entry_expose {
	my $self = shift;
	my ($widget) = @_;
	my $markup = $self->xpath_markup;
	$markup = '' unless defined $markup;
	$widget->get_layout->set_markup($markup);
}


#
# Called when the file choser is requested (File > Open).
#
sub callback_file_open {
	my $self = shift;
	$self->glade->get_widget('file')->show_all();
}


#
# Called when the file choser has chosen a file (File > Open).
#
sub callback_file_selected {
	my $self = shift;
	my ($dialog, $response) = @_;
	
	# The open button send the response 'accept'
	if ($response eq 'accept') {
		my $file = $dialog->get_filename;
		$self->load_file($file);
	}
	
	$dialog->hide();
}


#
# Called when the about dialog has to be displayed (Help > About).
#
sub callback_about_show {
	my $self = shift;
	$self->glade->get_widget('about')->show_all();
}


#
# Called when the a dialog has to be hidden. It's important that the dialog is
# not destroyed because Glade will not recreate it. If the dialog is destroyed
# the next time that dialog will be requested this will cause an error and the
# dialog will not be displayed.
#
# This method will simply hide the dialog and request that the dialog is not
# destroyed by returning TRUE.
#
# This callback can be used for all dialogs.
#
sub callback_dialog_hide {
	my $self = shift;
	my ($dialog) = @_;
	$dialog->hide();
	return TRUE;
}


#
# Displays the given text in the statusbar
#
sub display_statusbar_message {
	my $self = shift;
	my ($message) = @_;
	
	my $statusbar = $self->glade->get_widget('statusbar');
	my $id = $self->statusbar_context_id;
	$statusbar->pop($id);
	$statusbar->push($id, $message);
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
