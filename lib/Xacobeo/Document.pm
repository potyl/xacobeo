=head1 NAME

Xacobeo::Document - An XML document and it's related information.

=head1 SYNOPSIS

	use Xacobeo::Document;
	
	my $document Xacobeo::Document->new('file.xml');
	
	my $namespaces = $document->namespaces(); # Hashref
	while (my ($prefix, $uri) = each %{ $namespaces }) {
		printf "%-5s: %s\n", $prefix, $uri;
	}
	
	my @nodes = $document->findnodes('/x:html//x:a[@href]');
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

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		source
		xml
		xpath
	)
);


=head2 new

Creates a new instance.

Parameters:

	$source: the source of the XML document, this can be a file name.

=cut

sub new {
	croak 'Usage: ', __PACKAGE__, '->new($source)' unless @_ > 1;
	my $class = shift;
	my ($source) = @_;
	
	my $self = bless {}, ref($class) || $class;
	
	$self->_load_document($source);

	return $self;	
}


=head2 find

Runs the given XPath query on the document and returns the results. The results
could be a node list or a single value like a boolean, a number or a scalar if
an expression is passed.

Parameters:

	$xpath: a valid XPath expression.

=cut

sub find {
	my $self = shift;
	my ($xpath) = @_;
	
	my $result;
	eval {
		$result = $self->xpath->find($xpath, $self->xml);
	};
	if (my $error = $@) {
		return;
	}
	
	return $result;
}


=head2 validate

Validates the syntax of the given XPath query. The syntax is validated within a
context that has the same namespaces as the ones defined in the current XML
document.

Parameters:

	$xpath: a valid XPath expression.

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


#
# Get/Set the namespaces.
#
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
	my ($source) = @_;
	
	$self->source($source);

	
	# Parse the document
	my $parser = _construct_xml_parser();

	my $xml = $parser->parse_file($source);
	$self->xml($xml);
	
	# Find the namespaces
	$self->namespaces(_get_all_namespaces($xml));
	
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
sub _fetch_namespaces {
	my ($node, $collected) = @_;

	if ($node->isa('XML::LibXML::Element')) {
		foreach my $namespace ($node->getNamespaces) {
			my $uri = $namespace->getData;
			$collected->{$uri} ||= $namespace->getLocalName;
		}
	}

	foreach my $child ($node->childNodes) {
		_fetch_namespaces($child, $collected);
	}
}


#
# Finds every namespace declared in the document.
#
# Each prefix is warrantied to be unique.
# The function will assign the first prefix seen for each namespace.
#
# The prefixes are returned in an hash ref of type ($prefix => $uri).
#
sub _get_all_namespaces {
	my ($node) = @_;

	# Find the namespaces ($uri -> $prefix)
	my %namespaces = ();
	_fetch_namespaces($node, \%namespaces);
	
	# Reverse the namespaces ($prefix -> $uri) and make sure that the prefixes
	# don't clash with each other.
	my $cleaned = {};
	my $index = 0;
	while (my ($uri, $prefix) = each %namespaces) {

		# Make sure that the prefixes are unique
		if (! defined $prefix or exists $cleaned->{$prefix}) {
			# Assign a new prefix until unique
			do {
				$prefix = 'default' . ($index ? $index : '');
				++$index;
			} while (exists $cleaned->{$prefix});
		}
		$cleaned->{$prefix} = $uri;
	}

	return $cleaned;
}


#
# Creates an XPath context which will have the namespaces of the current
# document registered.
#
sub _create_xpath_context {
	my $self = shift;
	
	my $context = XML::LibXML::XPathContext->new();

	# Add the namespaces to the XPath context
	while (my ($prefix, $uri) = each %{ $self->namespaces }) {
		$context->registerNs($prefix, $uri);
	}
	
	return $context;
}


# A true value
1;
