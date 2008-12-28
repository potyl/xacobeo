package Xacobeo::XS;

=head1 NAME

Xacobeo::XS - Functions rewritten in XS.

=head1 SYNOPSIS

	use Xacobeo::XS qw(populate_textview populate_treeview);
	
	populate_textview($textview, $node, $namespaces);
	populate_treeview($treeview, $node, $namespaces);

=head1 DESCRIPTION

This package provides some functions that are implemented through XS. These
functions are much faster than their Perl counterpart.

=head1 FUNCTIONS

The following functions are available:

=cut

use strict;
use warnings;

use base 'DynaLoader';
use Glib qw(TRUE FALSE);
use Gtk2;
use XML::LibXML;

sub dl_load_flags {0x01};

__PACKAGE__->bootstrap;


=head2 populate_textview

Populates a L<Gtk2::TextView> with the contents of an L<XML::LibXML::Node>. The
elements and attributes are displayed with the prefix corresponding to their
respective namespaces.

Parameters:

=over

=item * $textview

The text view to fill. Must be an instance of L<Gtk2::TextView> and include a
valid buffer (L<Gtk2::TextBuffer>).

=item * $node

The node to display in the the text view. Must be an instance of
L<XML::LibXML::Node>.

=item $namespaces

The namespaces declared in the document. Must be an hash ref where the keys are
the URIs and the values the prefixes of the namespaces.

=back	

=cut

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


=head2 populate_treeview

Populates a L<Gtk2::TreeView> with the contents of an L<XML::LibXML::Node>. The
tree will display only the nodes of type element. Furthermore, the elements are
displayed with the prefix corresponding to their respective namespaces.

Parameters:

=over

=item * $treeview

The text view to fill. Must be an instance of L<Gtk2::TreeView> and include a
valid buffer (L<Gtk2::TreeStore>).

=item * $node

The node to display in the the tree view. Must be an instance of
L<XML::LibXML::Node>.

=item $namespaces

The namespaces declared in the document. Must be an hash ref where the keys are
the URIs and the values the prefixes of the namespaces.

=back	

=cut

sub populate_treeview {
	my ($treeview, $node, $namespaces) = @_;
	my $store = $treeview->get_model;
	
	$treeview->set_model(undef);
	xacobeo_populate_gtk_tree_store($store, $node, $namespaces);
	$treeview->set_model($store);
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
