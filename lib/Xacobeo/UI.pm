package Xacobeo::UI;

=encoding utf8

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
use Gtk2::Pango qw(PANGO_WEIGHT_LIGHT PANGO_WEIGHT_BOLD);
use Gtk2::SourceView;

use Data::Dumper;
use Carp qw(croak);
use File::Spec::Functions qw(catfile);

use Xacobeo;
use Xacobeo::DomModel;
use Xacobeo::Document;
use Xacobeo::Utils qw(
	isa_dom_nodelist
	isa_dom_namespace
	escape_xml_attribute
	isa_dom_boolean
	isa_dom_number
	isa_dom_literal
	escape_xml_text
);
use Xacobeo::I18n qw(__ __x __n);
use Xacobeo::Timer;
use Xacobeo::Error;
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
		xpath_pango_attributes
		xpath_empty_attributes
		xpath_empty_text
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

=item * $domain

The i18n (gettext) domain to use for the translations.

=back

=cut

sub new {
	# Arguments
	my ($class, $app_folder, $domain) = @_;
	croak 'Usage: new($app_folder, $domain)'
      unless defined $app_folder and defined $domain;

	# Create an instance
	my $self = bless {}, ref($class) || $class;

	# Create the GUI
	$self->app_folder($app_folder);
	$self->construct_gui($domain);

	# Return the new instances
	return $self;
}


#
# This method constructs the GUI
#
sub construct_gui {
	# Arguments
	my ($self, $domain) = @_;

	my $folder = $self->app_folder();

	# Load the GUI definition from the glade files
	Gtk2::Glade->set_custom_handler(\&glade_custom_handler, $self);
	my $glade = Gtk2::GladeXML->new(
		catfile($folder, 'share', 'xacobeo', 'xacobeo.glade'),
		undef,
		$domain,
	);
	$self->glade($glade);

	my $window = $self->glade->get_widget('window');
	$window->set_title($APP_NAME);

	# Set the application's icon
	my $logo = Gtk2::Gdk::Pixbuf->new_from_file(catfile($folder, 'share', 'pixmaps', 'xacobeo.png'));
	$window->set_icon($logo);
	$self->glade->get_widget('about')->set_logo($logo);

	# Parse the Pango markup for the default value of the xpath entry widget
	($self->{xpath_empty_attributes}, $self->{xpath_empty_text}) = pango_span(
		__("XPath Expression..."),
		color => 'grey',
		size  => 'smaller',
	);

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

	# Create the list model for the Namespace view
	$self->construct_namespaces_view();

	# Add the version to the about dialog
	$self->glade->get_widget('about')->set_version($Xacobeo::VERSION);

	return;
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
	Xacobeo::DomModel::create_model_with_view( ##no critic (ProhibitCallsToUnexportedSubs)
		$treeview,
		sub {
			my ($node) = @_;
			# Display the node in results text view. Temporary hack, in the future
			# clicking on the node will display the node finition in the sourve view.
			$self->display_results($node);
		},
	);

	return;
}


#
# Displays an XML node into a text view. This mehtod clears the view of it's old
# content before displaying the new data.
#
sub display_xml_node {
	my ($self, $widget_name, $node) = @_;

	my $namespaces = $self->document ? $self->document->namespaces : undef;
	my $textview = $self->glade->get_widget($widget_name);

	# It's faster to disconnect the buffer from the view and to reconnect it back
	my $buffer = $textview->get_buffer;
	$textview->set_buffer(Gtk2::SourceView::Buffer->new(undef));
	$buffer->delete($buffer->get_start_iter, $buffer->get_end_iter);


	# A NodeList
	if (! defined $node) {
		buffer_add($buffer, error => __("Node is undef"));
	}
	elsif (ref($node) eq 'Xacobeo::Error') {
		buffer_add($buffer, error => $node->message);
	}
	elsif (isa_dom_nodelist($node)) {
		my @children = $node->get_nodelist;
		my $count = scalar @children;

		# Formatting using to indicate which result is being displayed
		my $i = 0;
		my $format = sprintf " %%%dd. ", length($count);

		foreach my $child (@children) {
			# Add the result count
			my $result = sprintf $format, ++$i;
			buffer_add($buffer, result_count => $result);

			if (isa_dom_namespace($child)) {
				# The namespaces nodes are an invention of XML::LibXML and they don't
				# work with the XS code, we deal with them manually
				buffer_add($buffer, syntax => q{ });
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

	return;
}



#
# Displays an XML node in the results text view and makes sure that the results
# view is shown. This mehtod clears the view of it's old content.
#
sub display_results {
	my ($self, $node) = @_;

	$self->display_xml_node('xpath-results', $node);
	$self->glade->get_widget('notebook')->set_current_page(0);

	return;
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
			my $path = Gtk2::TreePath->new_from_string($text_path);
			#my $iter = $namespaces_view->get_iter($path);
			#$namespaces_view->set($iter, 0, $new_text);
			return FALSE;
		}
	);

	$self->namespaces_view($namespaces_view);

	return;
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
	my ($self, $file, $type) = @_;
	$type ||= 'xml';

	my $timer = Xacobeo::Timer->start();

	# Parse the content
	my $t_load = Xacobeo::Timer->start(__('Load document'));
	my $document;
	eval {
		$document = Xacobeo::Document->new($file, $type);
		1;
	} or $self->display_statusbar_message(
		__x("Can't read {file}: {error}", file => $file, error => $@)
	);
	$self->document($document);
	undef $t_load;

	$self->populate_widgets($file);

	$timer->stop();
	if ($document) {
		my $format = __n(
			"Document loaded in %.3f second",
			"Document loaded in %.3f seconds",
			int($timer->elapsed),
		);
		$self->display_statusbar_message(sprintf $format, $timer->elapsed);
	}
	else {
		# Invoke the time elapsed this way the value is not printed to the console
		$timer->elapsed;
	}

	return;
}


#
# Populates the different widgets after a document has been loaded
#
sub populate_widgets {
	my ($self, $file) = @_;

	my $glade = $self->glade;
	$glade->get_widget('window')->set_title("$APP_NAME - $file");

	my $document = $self->document;
	my ($documentNode, $namespaces) = $document ? ($document->documentNode, $document->namespaces) : (undef, {});

	# Update the text widget
	my $t_syntax = Xacobeo::Timer->start(__('Syntax Highlight'));
	$self->display_xml_node('xml-document', $documentNode);
	undef $t_syntax;

	# Clear the previous results
	$glade->get_widget('xpath-results')->get_buffer->set_text(q{});

	# Populate the DOM view tree
	my $t_dom = Xacobeo::Timer->start(__('DOM Tree'));
	$self->populate_treeview($documentNode);
	undef $t_dom;


	# Populate the Namespaces view
	my @namespaces = ();
	while (my ($uri, $prefix) = each %{ $namespaces }) {
		push @namespaces, [$prefix, $uri];
	}
	@{ $self->namespaces_view->{data} } = @namespaces;

	$glade->get_widget('xpath-entry')->set_sensitive(TRUE);

	return;
}


#
# Populates the DOM tree view.
#
sub populate_treeview {
	my ($self, $node) = @_;

	my $treeview = $self->glade->get_widget('dom-tree-view');
	my $store = $treeview->get_model;

	$treeview->set_model(undef);
	if (defined $node and defined $store) {
		xacobeo_populate_gtk_tree_store($store, $node, $self->document->namespaces);
	}
	elsif (defined $store) {
		$store->clear();
	}
	$treeview->set_model($store);

	return;
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
	my ($self, $xpath) = @_;
	croak 'Usage: $xacobeo->set_xpath($xpath)' unless defined $xpath;

	if (defined $xpath) {
		$self->glade->get_widget('xpath-entry')->set_text($xpath);
	}

	return;
}


#
# Populates a text tag table.
#
sub populate_tag_table {
	my ($tag_table) = @_;

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

	add_tag($tag_table, error =>
		foreground => 'red',
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
	return;
}



#
# Adds the given text at the end of the buffer. The text is added with a tag
# which can be used for performing syntax highlighting.
#
sub buffer_add {
	my ($buffer, $tag, $string) = @_;
	$buffer->insert_with_tags_by_name($buffer->get_end_iter, $string, $tag);
	return;
}


#
# Called when the main window is closed
#
sub callback_window_close {
	Gtk2->main_quit;
	return;
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
	my $result;
	if (eval {
		$result = $self->document->find($xpath);
		1;
	}) {
		$timer->stop();
		my $count = isa_dom_nodelist($result) ? $result->size : 1;
		my $format = __n("Found %d result in %0.3fs", "Found %d results in %0.3fs", $count);
		$self->display_statusbar_message(
			sprintf $format, $count, $timer->elapsed
		);
	} else {
		$timer->stop();
		$result = Xacobeo::Error->new(xpath => $@);
		$self->display_statusbar_message(__("XPath query issued an error"));
	}

	# Display the results
	$self->display_results($result);

	return;
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
	my ($self, $widget) = @_;

	my $xpath = $widget->get_text;
	my $pango_attributes = undef;
	my $xpath_valid = FALSE;
	if ($xpath) {

		my $button = $self->glade->get_widget('xpath-evaluate');
		if ($self->document->validate($xpath)) {
			# The expression is valid
			$xpath_valid = TRUE;
		}
		else {
			# Mark the XPath expression as wrong
			#my $escaped = escape_xml_text($xpath);
			#my $markup = "<span underline='error' underline_color='red'>$escaped</span>";
			#($pango_attributes) = Gtk2::Pango->parse_markup($markup);
			($pango_attributes) = pango_span($xpath, underline => 'error', underline_color => 'red');
		}
	}
	$self->glade->get_widget('xpath-evaluate')->set_sensitive($xpath_valid);
	$self->xpath_pango_attributes($pango_attributes);


	$self->set_xpath_pango_attributes();


	# Force a redraw
	request_redraw($widget);

	return;
}


# Called at each expose event (redrawing), this happens a lot because of the
# cursor which blinks periodically. The markup is sometimes forgotten between
# redraws. This callback corrects this problem.
sub callback_xpath_entry_expose {
	my ($self, $widget) = @_;
	$self->set_xpath_pango_attributes();

	# Continue with the events
	return FALSE;
}


#
# This handler stops the widget from generating critical Pango warnings when the
# text selection gesture is performed. If there's no text in the widget we
# simply cancel the gesture.
#
# The gesture is done with: mouse button 1 pressed and dragged over the widget
# while the button is still pressed.
#
sub callback_xpath_entry_button_press {
	my ($self, $widget, $event) = @_;

	if ($widget->get_text or $event->button != 1) {
		# Propagate the event further since there's text in the widget
		return FALSE;
	}

	# Give focus to the widget but stop the text selection
	$widget->grab_focus();
	return TRUE;
}


#
# Called when the file choser is requested (File > Open).
#
sub callback_file_open {
	my $self = shift;
	$self->glade->get_widget('file')->show_all();
	return;
}


#
# Called when the file choser has chosen a file (File > Open).
#
sub callback_file_selected {
	my ($self, $dialog, $response) = @_;

	# The open button send the response 'accept'
	if ($response eq 'accept') {
		my $file = $dialog->get_filename;
		$self->load_file($file);
	}

	$dialog->hide();
	return;
}


#
# Called when the about dialog has to be displayed (Help > About).
#
sub callback_about_show {
	my $self = shift;
	my $about = $self->glade->get_widget('about');
	$about->show_all();
	return;
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
	my ($self, $dialog) = @_;
	$dialog->hide();
	return TRUE;
}


#
# Schedules a redraw of the widget.
#
# The text region must be invalidated in order to be repainted. This is true
# even if the markup text is the same as the one in the widget. Remember that
# the text in the Pango markup could turn out to be the same text that was
# previously in the widget but with new styles (this is most common when showing
# an error with a red underline). In such case the Gtk2::Entry will not refresh
# its appearance because the text didn't change. Here we are forcing the update.
#
sub request_redraw {
	my ($widget) = @_;

	return unless $widget->realized;

	my $size = $widget->allocation;
	my $rectangle = Gtk2::Gdk::Rectangle->new(0, 0, $size->width, $size->height);
	$widget->window->invalidate_rect($rectangle, TRUE);
	return;
}



#
# Applies the attributes to the widget. Gtk2::Pango::Layout::set_attributes()
# doesn't accept an undef value (a patch has been submitted in order to address
# this issue). So if the attributes are undef an empty attribute list has to be
# submitted instead.
#
sub set_xpath_pango_attributes {
	my $self = shift;

	my $widget = $self->glade->get_widget('xpath-entry');
	my $xpath = $widget->get_text;
	my $layout = $widget->get_layout;

	my $attributes;
	if ($xpath eq q{}) {
		# The widget is empty, show the empty text
		$layout->set_text($self->xpath_empty_text);
		$attributes = $self->xpath_empty_attributes;
	}
	elsif ($self->xpath_pango_attributes) {
		# Use the attributes set previously
		$attributes = $self->xpath_pango_attributes;
	}
	else {
		# Reset the attributes just in case
		$attributes = Gtk2::Pango::AttrList->new();
	}


	$layout->set_attributes($attributes);
	return;
}


#
# Displays the given text in the statusbar
#
sub display_statusbar_message {
	my ($self, $message) = @_;

	my $statusbar = $self->glade->get_widget('statusbar');
	my $id = $self->statusbar_context_id;
	$statusbar->pop($id);
	$statusbar->push($id, $message);
	return;
}


sub glade_custom_handler {
	my ($glade, $function, $name, undef, undef, undef, undef, $self) = @_;

	my $widget;
	if ($self->can($function)) {
		$widget = $self->$function();
	}
	else {
		my $message = __x("Can't create widget {name} because method {function} is missing", function => $function, name => $name);
		warn "$message\n";
		$widget = Gtk2::Label->new($message);
	}

	$widget->show_all();
	return $widget;
}


#
# Creates the view used to display the full XML document.
#
sub create_xml_document_view {
	my $self = shift;

	my $tag_table = populate_tag_table(Gtk2::SourceView::TagTable->new());
	my $buffer = Gtk2::SourceView::Buffer->new($tag_table);
	$buffer->set('highlight', FALSE);
	# This will disable the undo/redo forever
	$buffer->begin_not_undoable_action();

	my $widget = Gtk2::SourceView::View->new_with_buffer($buffer);
	$widget->set_editable(FALSE);
	$widget->set_show_line_numbers(TRUE);
	$widget->set_highlight_current_line(TRUE);

	return $widget;
}


#
# Creates the view used to display the XPath results.
#
sub create_xpath_results_view {
	my $self = shift;

	my $tag_table = populate_tag_table(Gtk2::TextTagTable->new());
	my $buffer = Gtk2::TextBuffer->new($tag_table);
	my $widget = Gtk2::TextView->new_with_buffer($buffer);
	$widget->set_editable(FALSE);

	return $widget;
}


#
# Returns the Pango attribute list and the text from a Pango markup span that
# would have the given attributes.
#
# This function creates a span element with the given attributes that wraps the
# given text. The text has it's content escaped.
#
sub pango_span {
	my ($text, %attributes) = @_;

	my $pango = "<span";
	while (my ($key, $value) = each %attributes) {
		$pango .= " $key='$value'";
	}
	$pango .= sprintf ">%s</span>", escape_xml_text($text);

	return Gtk2::Pango->parse_markup($pango);
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
