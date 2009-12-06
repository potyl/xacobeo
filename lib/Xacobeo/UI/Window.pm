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
use Xacobeo::I18n;

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
print Dumper (\@_);
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

	my $statusbar = Gtk2::Statusbar->new();
	$self->statusbar($statusbar);
	$main_vbox->pack_start($statusbar, FALSE, TRUE, 0);

}


#
# Called when a new file has to be loaded
#
sub do_file_open {
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
			$self->load_file($file);
		}

		$dialog->destroy();
	});
	$dialog->show();
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
			sub { $self->do_file_open(@_) }
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
