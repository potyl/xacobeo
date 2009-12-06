package Xacobeo::XS;

=encoding utf8

=head1 NAME

Xacobeo::XS - Functions rewritten in XS.

=head1 SYNOPSIS

	use Xacobeo::XS;
	
	Xacobeo::XS->load_text_buffer($textview->get_buffer, $node, $namespaces);
	Xacobeo::XS->load_tree_store($treeview->get_store, $node, $namespaces);

=head1 DESCRIPTION

This package provides some functions that are implemented through XS. These
functions are much faster than their Perl counterpart.

=head1 CLASS METHODS

The following class methods are available:

=head2 load_text_buffer

Populates a L<Gtk2::TextBuffer> with the contents of an L<XML::LibXML::Node>.
The elements and attributes are displayed with the prefix corresponding to their
respective namespaces. The XML document is also displayed with proper syntax
highlighting.

Parameters:

=over

=item * $buffer

The text buffer to fill. Must be an instance of L<Gtk2::TextBuffer>.

=item * $node

The node to display in the the text view. Must be an instance of
L<XML::LibXML::Node>.

=item $namespaces

The namespaces declared in the document. Must be an hash ref where the keys are
the URIs and the values the prefixes of the namespaces.

=back

=head2 load_tree_store

Populates a L<Gtk2::TreeStore> with the contents of an L<XML::LibXML::Node>. The
tree will display only the nodes of type element. Furthermore, the elements are
displayed with the prefix corresponding to their respective namespaces.

Parameters:

=over

=item * $store

The text store to fill. Must be an instance of L<Gtk2::TreeStore>.

=item * $node

The node to display in the the tree view. Must be an instance of
L<XML::LibXML::Node>.

=item $namespaces

The namespaces declared in the document. Must be an hash ref where the keys are
the URIs and the values the prefixes of the namespaces.

=back

=cut

use 5.006;
use strict;
use warnings;

use parent qw(DynaLoader);
use Gtk2;
use XML::LibXML;

use Exporter 'import';
our @EXPORT_OK = qw(
	xacobeo_populate_gtk_text_buffer
	xacobeo_populate_gtk_tree_store
);


sub dl_load_flags {return 0x01}


sub load_text_buffer {
	my $class = shift;
	my ($buffer, $node, $namespaces) = @_;
	xacobeo_populate_gtk_text_buffer($buffer, $node, $namespaces);
}


sub load_tree_store {
	my $class = shift;
	my ($store, $node, $namespaces) = @_;
	xacobeo_populate_gtk_tree_store($store, $node, $namespaces);
}


__PACKAGE__->bootstrap;


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
