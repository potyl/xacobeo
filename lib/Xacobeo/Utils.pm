package Xacobeo::Utils;

=encoding utf8

=head1 NAME

Xacobeo::Utils - Utilities shared among the project.

=head1 SYNOPSIS

	use Xacobeo::Utils qw(:dom :xml);
	
	if (isa_dom_text($node)) {
		my $text = escape_xml_text($node->nodeValue);
		print "$text\n";
	}

=head1 DESCRIPTION

This package provides utility methods and constants that are shared among
the different modules in this project.

=head1 IMPORTS

The constants C<$EMPTY> and C<$SPACE> are available on demand.
Additionally, the following import tags are defined:

=head2 :xml

Import the XML utilities.

=head2 :dom

Imports the DOM utilities.

=head1 FUNCTIONS

The following functions are available:

=cut

use 5.006;
use strict;
use warnings;

use Readonly qw(Scalar);
use XML::LibXML;

use Exporter 'import';
Scalar our $EMPTY => q{};
Scalar our $SPACE => q{ };
our @EXPORT_OK = qw(
	escape_xml_text
	escape_xml_attribute

	isa_dom_document
	isa_dom_element
	isa_dom_attr
	isa_dom_nodelist
	isa_dom_text
	isa_dom_comment
	isa_dom_literal
	isa_dom_boolean
	isa_dom_number
	isa_dom_node
	isa_dom_pi
	isa_dom_dtd
	isa_dom_cdata
	isa_dom_namespace

	$EMPTY
	$SPACE
);

our %EXPORT_TAGS = (
	'xml' => [
		qw(
			escape_xml_text
			escape_xml_attribute
		)
	],

	'dom' => [
		qw(
			isa_dom_document
			isa_dom_element
			isa_dom_attr
			isa_dom_nodelist
			isa_dom_text
			isa_dom_comment
			isa_dom_literal
			isa_dom_boolean
			isa_dom_number
			isa_dom_node
			isa_dom_pi
			isa_dom_dtd
			isa_dom_cdata
			isa_dom_namespace
		)
	],
);


# The entities defined in XML
my %ENTITIES = qw(
	<  &lt;
	>  &gt;
	&  &amp;
	'  &apos;
	"  &quot;
);



=head2 escape_xml_text

Escapes the text as if would be added to a Text node. This function escapes only
the entities <, > and &.

Parameters:

=over

=item * $string

The string to escape.

=back

=cut

sub escape_xml_text {
	my ($string) = @_;
	$string =~ s{
		( [<>&] ) # capture any literal < > &
	}{
		$ENTITIES{$1}
	}egmsx; # and replace all
	return $string;
}



=head2 escape_xml_attribute

Escapes the text as if would be added to an Attribute. This function escapes the
entities <, >, &, ' and ".

Parameters:

=over

=item * $string

The string to escape.

=back

=cut

sub escape_xml_attribute {
	my ($string) = @_;
	$string =~ s{
		( [<>&'"] )  # capture any literal < > & ' "
	}{
		$ENTITIES{$1}
	}egmsx; # and replace all
	return $string;
}



=head2 isa_dom_document

Returns true if the node is a DOM C<Document> (instance of
L<XML::LibXML::Document>).

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_document {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Document') : 0;
}



=head2 isa_dom_element

Returns true if the node is a DOM C<Element> (instance of
L<XML::LibXML::Element>).

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_element {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Element') : 0;
}



=head2 isa_dom_attr

Returns true if the node is a DOM C<Attribute> (instance of
L<XML::LibXML::Attr>).

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_attr {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Attr') : 0;
}



=head2 isa_dom_nodelist

Returns true if the node is a DOM C<NodeList> (instance of
L<XML::LibXML::NodeList>).

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_nodelist {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::NodeList') : 0;
}



=head2 isa_dom_text

Returns true if the node is a DOM C<Text> (instance of
L<XML::LibXML::Text>).

B<NOTE>: XML::LibXML considers that C<Comment> and C<CDATA> nodes are also
C<Text> nodes. This method doesn't consider a C<Comment> nor a C<CDATA> node as
being C<Text> nodes.

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_text {
	my ($node) = @_;
	return unless defined $node;
	return if isa_dom_comment($node) or isa_dom_cdata($node);
	return $node->isa('XML::LibXML::Text');
}



=head2 isa_dom_comment

Returns true if the node is a DOM C<Comment> (instance of
L<XML::LibXML::Comment>).

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_comment {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Comment') : 0;
}



=head2 isa_dom_node

Returns true if the node is a DOM C<Node> (instance of
L<XML::LibXML::Node>).

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_node {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Node') : 0;
}



=head2 isa_dom_pi

Returns true if the node is a DOM C<PI> (also known as: processing instruction)
(instance of L<XML::LibXML::PI>).

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_pi {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::PI') : 0;
}



=head2 isa_dom_dtd

Returns true if the node is a DOM C<DTD> (instance of
L<XML::LibXML::Dtd>).

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_dtd {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Dtd') : 0;
}



=head2 isa_dom_cdata

Returns true if the node is a DOM C<CDATASection> (instance of
L<XML::LibXML::CDATASection>).

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_cdata {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::CDATASection') : 0;
}



=head2 isa_dom_namespace

Returns true if the node is a C<Namespace> (instance of
L<XML::LibXML::Namespace>).

B<NOTE>: The DOM doesn't define an object type named C<Namespaces> but
XML::LibXML does so this function is named 'isa_dom' for consistency with the
other functions.

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_namespace {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Namespace') : 0;
}



=head2 isa_dom_literal

Returns true if the node is a C<Literal> (instance of
L<XML::LibXML::Literal>).

B<NOTE>: The DOM doesn't define an object type named C<Literal> but XML::LibXML
does so this function is named 'isa_dom' for consistency with the other
functions.

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_literal {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Literal') : 0;
}



=head2 isa_dom_boolean

Returns true if the node is a C<Boolean> (instance of
L<XML::LibXML::Boolean>).

B<NOTE>: The DOM doesn't define an object type named C<Boolean> but XML::LibXML
does so this function is named 'isa_dom' for consistency with the other
functions.

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_boolean {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Boolean') : 0;
}



=head2 isa_dom_number

Returns true if the node is a C<Number> (instance of
L<XML::LibXML::Number>).

B<NOTE>: The DOM doesn't define an object type named C<Number> but XML::LibXML
does so this function is named 'isa_dom' for consistency with the other
functions.

Parameters:

=over

=item * $node

The node to check.

=back

=cut

sub isa_dom_number {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Number') : 0;
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
