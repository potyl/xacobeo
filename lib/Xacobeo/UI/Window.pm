package Xacobeo::UI::Window;

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::SimpleList;

use Xacobeo;
use Xacobeo::UI::SourceView;
use Xacobeo::UI::DomView;
use Xacobeo::UI::Statusbar;
use Xacobeo::I18n;
use Xacobeo::Timer;
use Xacobeo::Document;

use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		source_view
		dom_view
		results_view
		namespaces_view
		statusbar
		conf
	)
);

use Glib::Object::Subclass 'Gtk2::Window';


sub INIT_INSTANCE {
	my $self = shift;

	my $conf = Xacobeo::Conf->get_conf;
	$self->conf($conf);

	# Pimp a bit the window (title, icon
	$self->set_title($conf->app_name);

	$self->set_icon(
		Gtk2::Gdk::Pixbuf->new_from_file(
			$conf->share_file('pixmaps', 'xacobeo.png')
		)
	);

	$self->set_size_request(800, 600);


	# Build the window's widgets
	my $main_vbox = Gtk2::VBox->new(FALSE, 0);
	$self->add($main_vbox);

	$main_vbox->pack_start($self->_create_menu, FALSE, FALSE, 0);
	$main_vbox->pack_start($self->_create_search_bar, FALSE, TRUE, 0);
	$main_vbox->pack_start($self->_create_main_content, TRUE, TRUE, 0);

	my $statusbar = Xacobeo::UI::Statusbar->new();
	$self->statusbar($statusbar);
	$main_vbox->pack_start($statusbar, FALSE, TRUE, 0);

}


=head2 load_file

This method loads a new file into the GUI. The new document will be parsed and
displayed in the window.

Parameters:

=over

=item * $file

The file to load.

=item * $type

The type of document to load (xml, html).

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
	} or do {
		my $error = $@;
		$self->statusbar->display(
			__x("Can't read {file}: {error}", file => $file, error => $error)
		);
	};
	undef $t_load;


	# Fill the widgets
	$self->set_title($self->conf->app_name . ' - ' . $file);
	
	my ($node, $namespaces) = $document ? ($document->documentNode, $document->namespaces) : (undef, {});
	
	# Update the text widget
	my $t_syntax = Xacobeo::Timer->start(__('Syntax Highlight'));
	$self->source_view->set_document($document);
	$self->source_view->show_node($node);
	undef $t_syntax;

	# Clear the previous results
	$self->results_view->clear();

	# Populate the DOM view tree
	my $t_dom = Xacobeo::Timer->start(__('DOM Tree'));
#	$self->populate_treeview($document_node);
	undef $t_dom;


	# Populate the Namespaces view
	my @namespaces;
	while (my ($uri, $prefix) = each %{ $namespaces }) {
		push @namespaces, [$prefix, $uri];
	}
	@{ $self->namespaces_view->{data} } = @namespaces;

#	$glade->get_widget('xpath-entry')->set_sensitive(TRUE);


	# Show the timers
	$timer->stop();
	if ($document) {
		my $format = __n(
			"Document loaded in %.3f second",
			"Document loaded in %.3f seconds",
			int($timer->elapsed),
		);
		$self->statusbar->displayf($format, $timer->elapsed);
	}
	else {
		# Invoke the time elapsed this way the value is not printed to the console
		$timer->elapsed;
	}

	return;
}


#
# Called when a new file has to be loaded
#
sub do_show_file_open_dialog {
	my $self = shift;

	my $dialog = Gtk2::FileChooserDialog->new(
		__("Open file..."),
		$self, # parent window
		'open',
		'gtk-cancel' => 'cancel',
		'gtk-ok'     => 'ok',
	);

	$dialog->signal_connect(response => sub {
		my ($dialog, $response) = @_;

		if ($response eq 'ok') {
			my $file = $dialog->get_filename;
			print "File is $file\n";
			return if -d $file;
			$self->load_file($file, 'xml');
		}

		$dialog->destroy();
	});

	$dialog->run();
}


#
# Called when the window has to be closed
#
sub do_quit {
	my $self = shift;
	$self->destroy();
	return;
}


#
# Called when the about dialog has to be shown
#
sub do_show_about_dialog {
	my $self = shift;

	my $name = $self->conf->app_name;

	my $dialog = Gtk2::AboutDialog->new();
	$dialog->set_title(__x("About {name}", name => $name));
	$dialog->set_program_name($self->conf->app_name);
	$dialog->set_logo($self->get_icon);
	$dialog->set_version($Xacobeo::VERSION);

	$dialog->set_authors('Emmanuel Rodriguez <potyl@cpan.org>');
	$dialog->set_copyright("Copyright (C) 2008-2009 by Emmanuel Rodriguez.");
	$dialog->set_translator_credits(join "\n",
		'Emmanuel Rodriguez <potyl@cpan.org>',
		'Lars Dieckow <daxim@cpan.org>',
	);

	$dialog->set_website('http://code.google.com/p/xacobeo/');
	$dialog->set_website_label($name);

	$dialog->set_comments(__("Simple XPath viewer"));
	$dialog->signal_connect(response => sub {
		my ($dialog, $response) = @_;
		$dialog->destroy();
	});
	$dialog->show();
}


sub _create_menu {
	my $self = shift;

	# This entries are always active
	my $active_entries = [
		# Top level
		[ 'FileMenu',  undef, "_File" ],
		[ 'HelpMenu',  undef, "_Help" ],


		# Entries (name, stock id, label, accelerator, tooltip, callback)
		[
			'FileOpen',
			'gtk-open',
			__("_Open"),
			'<control>O',
			__("Open a file"),
			sub { $self->do_show_file_open_dialog(@_) }
		],
		[
			'FileQuit',
			'gtk-quit',
			__("_Quit"),
			"<control>Q",
			__("Quit"),
			sub { $self->do_quit() }
		],


		[
			'HelpAbout',
			'gtk-about',
			__("_About"),
			undef,
			__("About"),
			sub { $self->do_show_about_dialog(@_) }
		],
	];

	my $actions = Gtk2::ActionGroup->new("Actions");
	$actions->add_actions($active_entries, undef);

	my $ui = Gtk2::UIManager->new();
	$ui->insert_action_group($actions, 0);
	$ui->add_ui_from_string(<<'__UI__');
<ui>
	<menubar name='MenuBar'>

		<menu action='FileMenu'>
			<menuitem action='FileOpen'/>
			<placeholder name="FilePlaceholder_1"/>

			<separator/>

			<placeholder name="FilePlaceholder_2"/>
			<menuitem action='FileQuit'/>
		</menu>


		<placeholder name="ExtraMenu"/>


		<menu action='HelpMenu'>
			<menuitem action='HelpAbout'/>
		</menu>

	</menubar>
</ui>
__UI__

	$self->add_accel_group($ui->get_accel_group);

	return $ui->get_widget('/MenuBar');
}


sub _create_search_bar {
	my $self = shift;
	my $hbox = Gtk2::HBox->new();
	
	my $label = Gtk2::Label->new(__("XPath:"));
	$hbox->pack_start($label, FALSE, TRUE, 0);
	
	my $entry = Gtk2::Entry->new();
	$hbox->pack_start($entry, TRUE, TRUE, 0);
	
	my $button = Gtk2::Button->new(__("Evaluate"));
	$hbox->pack_start($button, FALSE, TRUE, 0);
	
	return $hbox;
}


sub _create_main_content {
	my $self = shift;

	my $hpaned = Gtk2::HPaned->new();

	# Left part - Tree view
	my $dom_view = Xacobeo::UI::DomView->new();
	$self->dom_view($dom_view);
	$hpaned->pack1(_scroll($dom_view, 200), FALSE, TRUE);


	# Rigth part - VPaned [Source view | Notebook(Results, Namespaces)]
	my $vpaned = Gtk2::VPaned->new();
	$hpaned->pack2($vpaned, TRUE, TRUE);

	my $source_view = Xacobeo::UI::SourceView->new();
	$self->source_view($source_view);
	$source_view->set_show_line_numbers(TRUE);
	$source_view->set_highlight_current_line(TRUE);
	$vpaned->pack1(_scroll($source_view, -1, 400), FALSE, TRUE);
	
	
	# Notebook with the results view and the namespaces view
	my $notebook = Gtk2::Notebook->new();
	$vpaned->pack2($notebook, TRUE, TRUE);

	my $results_view = Xacobeo::UI::SourceView->new();
	$self->results_view($results_view);
	$notebook->append_page(
		_scroll($results_view),
		Gtk2::Label->new(__("Results"))
	);
	
	my $namespaces_view = Gtk2::SimpleList->new(
		__('Prefix') => 'text',
		__('URI')    => 'text',
	);
	$self->namespaces_view($namespaces_view);
	$notebook->append_page(
		_scroll($namespaces_view),
		Gtk2::Label->new(__("Namespaces"))
	);
	
	return $hpaned;
}


sub _scroll {
	my ($widget, $width, $height) = @_;
	$width = -1 unless defined $width;
	$height = -1 unless defined $height;
	
	my $scroll = Gtk2::ScrolledWindow->new();
	$scroll->set_policy('automatic', 'automatic');
	$scroll->set_shadow_type('in');
	$scroll->set_size_request($width, $height);
	
	$scroll->add($widget);
	return $scroll;
}


1;
