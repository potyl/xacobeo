package Xacobeo::XS;

use strict;
use warnings;

use base 'DynaLoader';
use Glib qw(TRUE FALSE);
use Gtk2;
use XML::LibXML;

our $VERSION = '0.05_01';

sub dl_load_flags {0x01};
__PACKAGE__->bootstrap;


sub populate_textview {
	my ($textview, $node, $namespaces) = @_;
	my $buffer = $textview->get_buffer;

	# It's faster to disconnect the buffer from the view and to reconnect it back
	$textview->set_buffer(Gtk2::TextBuffer->new());# Perl-Gk2 Bug can't set undef as a buffer
	xacobeo_populate_gtk_text_buffer($buffer, $node, $namespaces);
	$textview->set_buffer($buffer);

	# Scroll to tbe beginning
	$textview->scroll_to_iter($buffer->get_start_iter, 0.0, FALSE, 0.0, 0.0);
}


#sub populate_treeview($treeview, $document, $namespaces);



1;
