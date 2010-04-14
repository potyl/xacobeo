#!/usr/bin/perl

use strict;
use warnings;

use blib;
use lib 'lib';

use Glib qw(TRUE FALSE);
use Gtk2 '-init';

use Xacobeo::Utils qw{scrollify};
use Xacobeo::Model::DomElements;
use Xacobeo::Document;
use Xacobeo::UI::DomView;

exit main() unless caller;


sub main {

	my $document = Xacobeo::Document->new_from_file('tests/sample.xml', 'xml');
#	print $document->documentNode, "\n";

	my $model = Xacobeo::Model::DomElements->new($document->documentNode);

	my $window = Gtk2::Window->new();
	$window->set_size_request(200, 200);
	
	my $view = create_tree_view();
	$view->set_model($model);
	$window->add(scrollify($view));

	$window->signal_connect(destroy => sub {Gtk2->main_quit(); });	

	$window->show_all();
	Gtk2->main();

	return 0;
}


sub create_tree_view {
	my $view = Gtk2::TreeView->new();
	my $column = Xacobeo::UI::DomView::_add_text_column($view, 1, 'Element', 150);
	return $view;
}
