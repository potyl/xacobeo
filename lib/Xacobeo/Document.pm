=head1 NAME

Xacobeo::Document - An XML document and it's related information.

=head1 SYNOPSIS

	use Xacobeo::Document;
	
	my $document = Xacobeo::Document->new('file.xml', 'xml');
	
	my $namespaces = $document->namespaces(); # Hashref
	while (my ($uri, $prefix) = each %{ $namespaces }) {
		printf "%-5s: %s\n", $prefix, $uri;
	}
	
	
	my $nodes = $document->find('/x:html//x:a[@href]');
	foreach my $node ($nodes->get_nodelist) {
		print "Got node ", $node->name, "\n";
	}
	
	$document->validate('/x:html//x:a[@href]') or die "Invalid XPath expression";

=head1 DESCRIPTION

This package wraps an XML document with it's corresponding meta information
(namespaces, source, etc).

=head1 METHODS

The package defines the following methods:

=cut

package Xacobeo::Document;

use strict;
use warnings;

use XML::LibXML;
use Data::Dumper;
use Carp;

use Xacobeo::Utils qw(:dom);
use Xacobeo::I18n;


use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		source
		documentNode
		xpath
	)
);


=head2 new

Creates a new instance.

Parameters:

	$source: the source of the XML document, this can be a file name.

=cut

sub new {
	croak 'Usage: ', __PACKAGE__, '->new($source, $type)' unless @_ == 3;
	my $class = shift;
	my ($source, $type) = @_;
	
	my $self = bless {}, ref($class) || $class;
	
	$self->_load_document($source, $type);

	return $self;	
}


=head2 find

Runs the given XPath query on the document and returns the results. The results
could be a node list or a single value like a boolean, a number or a scalar if
an expression is passed. This method always return its values in scalar context.

This method croaks if the expression can't be evaluated.

Parameters:

	$xpath: the XPath expression to execute.

=cut

sub find {
	my $self = shift;
	my ($xpath) = @_;
	croak __("Document node is missing") unless defined $self->documentNode;
	
	my $result;
	eval {
		$result = $self->xpath->find($xpath, $self->documentNode);
	};
	if (my $error = $@) {
		croak $error;
	}
	
	return $result;
}


=head2 validate

Validates the syntax of the given XPath query. The syntax is validated within a
context that has the same namespaces as the ones defined in the current XML
document.

B<NOTE>: This method can't validate if undefined functions or variables are
used.

Parameters:

	$xpath: the XPath expression to validate.

=cut

sub validate {
	my $self = shift;
	my ($xpath) = @_;

	# Validate the XPath expression in an empty document, this is a performance
	# trick. If the XPath expression is something insane '//*' we don't want to
	# take for ever just for a validation.
	my $empty = XML::LibXML->createDocument();
	eval {
		$self->xpath->find($xpath, $empty);
	};
	if (my $error = $@) {
#		print Dumper($error);
#		warn "Failed to process the XPath expression '$xpath' because: $error.";
		return;
	}

	return 1;
}


=head2 get_prefixed_name

Returns the node name by prefixing it with our prefixes in the case where
namespaces are used.

=cut

sub get_prefixed_name {
	my $self = shift;
	my ($node) = @_;

	my $name = $node->localname;
	my $uri = $node->namespaceURI();

	# Check if the node uses a namespace if so return the name with our prefix
	if (defined $uri and my $namespace = $self->{namespaces}{$uri}) {
		return "$namespace:$name";
	}

	return $name;
}



=head2 namespaces

Returns the namespaces declared in the document. The namespaces are returned in
a hashref where the URIs are used as a key and the prefix as a value.

=cut

sub namespaces {
	my $self = shift;
	if (@_) {
		$self->{namespaces} = $_[0];
	}
	return $self->{namespaces};
}


#
# Loads the XML document. This method will also find the namespaces used in the
# document.
#
sub _load_document {
	my $self = shift;
	my ($source, $type) = @_;
	
	$self->source($source);

	
	# Parse the document
	my $parser = _construct_xml_parser();
	my $documentNode;
	if (! defined $type) {
		croak "Parameter type must be defined";
	}
	elsif ($type eq 'xml') {
		$documentNode = $parser->parse_file($source);
	}
	elsif ($type eq 'html') {
		$documentNode = $parser->parse_html_file($source);
	}
	else {
		croak __x("Unsupported document type {type}", type => $type);
	}
	$self->documentNode($documentNode);
	
	# Find the namespaces
	$self->namespaces(_get_all_namespaces($documentNode));
	
	# Create the XPath context
	$self->xpath(
		$self->_create_xpath_context()
	);
}


#
# Creates and setups the internal XML parser to use by this instance.
#
sub _construct_xml_parser {

	my $parser = XML::LibXML->new();
	$parser->line_numbers(1);
	$parser->recover_silently(1);
	$parser->complete_attributes(0);
	
	return $parser;
}


#
# Finds every namespace declared in the document.
#
# Each prefix is warrantied to be unique. The function will assign the first
# prefix seen for each namespace.
#
# NOTE: libxml2 assumes that the prefix 'xml' is is bounded to the URI
#       http://www.w3.org/XML/1998/namespace, therefore this namespace will
#       always be returned even if it's not declared in the document.
#
# The prefixes are returned in an hash ref of type ($uri => $prefix).
#
sub _get_all_namespaces {
	my ($node) = @_;

	# Find the namespaces ($uri -> $prefix)
	my %seen = (
		XML_XML_NS() => [xml => XML_XML_NS()],
	);
	# Namespaces found following the document order
	my @namespaces = (values %seen);
	if ($node) {
		foreach my $namespace ($node->findnodes('.//namespace::*')) {
			my $uri = $namespace->getData;
			my $name = $namespace->getLocalName;
			if (! defined $uri) {
				warn __x("Namespace {name} has no URI", name => $name);
				$uri = '';
			}
			
			# If the namespace was seen before make sure that we have a decent prefix.
			# Maybe the previous time there was no prefix associated.
			if (my $record = $seen{$uri}) {
				$record->[0] ||= $name; 
				next;
			}

			# First time that this namespace is seen
			my $record = [$name => $uri];
			$seen{$uri} = $record;
			push @namespaces, $record;
		}
	}

	# Make sure that the prefixes are unique.
	my %cleaned = ();
	my $namespaces = {};
	my $index = 0;
	foreach my $record (@namespaces) {
		my ($prefix, $uri) = @{ $record };

		# Don't provide a namespace prefix for the default namespace (xmlns="")
		next if ! defined $prefix && $uri eq "";

		# Make sure that the prefixes are unique
		if (! defined $prefix or exists $cleaned{$prefix}) {
			# Assign a new prefix until unique
			do {
				$prefix = 'default' . ($index || '');
				++$index;
			} while (exists $cleaned{$prefix});
		}
		$cleaned{$prefix} = $uri;
		$namespaces->{$uri} = $prefix;
	}
	return $namespaces;
}


#
# Creates an XPath context which will have the namespaces of the current
# document registered.
#
sub _create_xpath_context {
	my $self = shift;
	
	my $context = XML::LibXML::XPathContext->new();

	# Add the namespaces to the XPath context
	while (my ($uri, $prefix) = each %{ $self->namespaces }) {
		$context->registerNs($prefix, $uri);
	}
	
	return $context;
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

