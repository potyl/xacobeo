package Xacobeo::Utils;

=head1 NAME

Xacobeo::Utils - Utilities shared among the project.

=head1 SYNOPSIS

	use Xacobeo::Utils qw(:dom :xml);
	
	if (isa_dom_text($node)) {
		my $text = escape_xml_text($node->nodeValue);
		print "$text\n";
	}

=head1 DESCRIPTION

This package provides utility methods that are shared among the different
modules in this project.


=head1 FUNCTIONS

The following functions are available:

=cut

use strict;
use warnings;

use XML::LibXML;

use Exporter 'import';
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


=head2

=cut
#
# Escapes the text as if would be added to a Text node. This function escapes
# only the entities <, > and &.
#
sub escape_xml_text {
	my ($string) = @_;
	$string =~ s/([<>&])/$ENTITIES{$1}/eg;
	return $string;
}


#
# Escapes the text as if would be added to an Attribute. This function escapes
# the entities <, >, &, ' and ".
#
sub escape_xml_attribute {
	my ($string) = @_;
	$string =~ s/([<>&'"])/$ENTITIES{$1}/eg;
	return $string;
}


sub isa_dom_document {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Document') : 0;
}


sub isa_dom_element {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Element') : 0;
}


sub isa_dom_attr {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Attr') : 0;
}


sub isa_dom_nodelist {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::NodeList') : 0;
}


#
# Return true if the node is a text as defined in the DOM.
#
# NOTE: XML::LibXML decided that Comment and CDATA nodes are also a Text node.
#       Despite XML::LibXML this method doesn't consider a Coment nor a CDATA
#       node as being a Text node.
#
sub isa_dom_text {
	my ($node) = @_;
	return unless defined $node;
	return if isa_dom_comment($node) or isa_dom_cdata($node);
	return $node->isa('XML::LibXML::Text');
}


sub isa_dom_comment {
	my ($node) = @_;
	return unless defined $node;
	return defined $node ? $node->isa('XML::LibXML::Comment') : 0;
}


sub isa_dom_literal {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Literal') : 0;
}


sub isa_dom_boolean {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Boolean') : 0;
}


sub isa_dom_number {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Number') : 0;
}


sub isa_dom_node {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Node') : 0;
}


sub isa_dom_pi {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::PI') : 0;
}


sub isa_dom_dtd {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Dtd') : 0;
}


sub isa_dom_cdata {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::CDATASection') : 0;
}


sub isa_dom_namespace {
	my ($node) = @_;
	return defined $node ? $node->isa('XML::LibXML::Namespace') : 0;
}

1;

=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
