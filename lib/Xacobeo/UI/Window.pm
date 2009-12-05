package Xacobeo::UI::Window;

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::SimpleList;
use Xacobeo::UI::SourceView;
use Xacobeo::UI::DomView;
use Xacobeo::I18n qw(__);

use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		source_view
		dom_view
		results_view
		namespaces_view
		statusbar
	)
);

use Glib::Object::Subclass 'Gtk2::Window';


sub INIT_INSTANCE {
	my $self = shift;

	my $main_vbox = Gtk2::VBox->new(FALSE, 0);
	$self->add($main_vbox);
	
	# Add menu bar
	$main_vbox->pack_start($self->_create_search_bar, FALSE, TRUE, 0);
	$main_vbox->pack_start($self->_create_main_content, TRUE, TRUE, 0);

	my $statusbar = Gtk2::Statusbar->new();
	$self->statusbar($statusbar);
	$main_vbox->pack_start($statusbar, FALSE, TRUE, 0);

}


sub _create_search_bar {
	my $self = shift;
	my $hbox = Gtk2::HBox->new();
	
	my $label = Gtk2::Label->new(__("XPath:"));
	$hbox->pack_start($label, FALSE, TRUE, 0);
	
	my $entry = Gtk2::Entry->new();
	$hbox->pack_start($entry, TRUE, TRUE, 0);
	
	my $entry = Gtk2::Button->new(__("Evaluate"));
	$hbox->pack_start($entry, FALSE, TRUE, 0);
	
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
