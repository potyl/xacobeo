#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;
use Data::Dumper;

BEGIN {
	use_ok('Xacobeo::Document');
}

my $FOLDER = "tests";

exit main();


sub main {
	
	test_without_namespaces();
	
	test_namespaces();
	
	return 0;
}


sub test_without_namespaces {
	my $document = Xacobeo::Document->new("$FOLDER/xorg.xml");
	isa_ok($document, 'Xacobeo::Document');
	
	is_deeply(
		$document->namespaces(),
		{},
		'Document without namespaces'
	);
	
	my $count;
	my $valid;
	my @nodes;
	

	# Look for a non existing node
	$count = $document->findnodes('//x');
	is($count, 0, 'Count for non existing element');

	@nodes = $document->findnodes('//x');
	is_deeply(
		\@nodes,
		[],
		'Nodes from a non existing element'
	);

	
	# Test that an invalid xpath expression doesn't throw an error
	$count = $document->findnodes('//x/');
	is($count, undef, 'Count from an invalid XPath expression');
	@nodes = $document->findnodes('//x/');
	is_deeply(
		\@nodes,
		[],
		'Nodes from an invalid XPath expression'
	);


	# Find a existing node set
	$count = $document->findnodes('//description[@xml:lang="es"]');
	is($count, 461, 'Count from a lot of nodes');

	@nodes = $document->findnodes('//description[@xml:lang="es"]');
	is(scalar @nodes, 461, 'A lot of nodes');
	

	# Fails because the namespace doesn't exist
	$valid = $document->validate('/x:html//x:a[@href]');
	ok(! $valid, 'Validate XPath query with undefined namespaces');
	$count = $document->findnodes('/x:html//x:a[@href]');
	is($count, undef, 'XPath query uses undefined namespaces');

	
	# Fails because the syntax is invalid
	$valid = $document->validate('/html//a[@href');
	ok(! $valid, 'Validate XPath query with invalid syntax');
	$count = $document->findnodes('/html//a[@href');
	is($count, undef, 'Invalid XPath syntax');

	
	# Fails because the function aaa() is not defined
	$valid = $document->validate('aaa(1)');
	ok(! $valid, 'Validate XPath query with an undefined function');
	$count = $document->findnodes('aaa(1)');
	is($count, undef, 'Undefined XPath function');

	
	# This is fine
	$valid = $document->validate('/xkbConfigRegistry');
	ok($valid, 'Validate XPath query');
}



sub test_namespaces {
	my $document = Xacobeo::Document->new("$FOLDER/SVG.svg");
	isa_ok($document, 'Xacobeo::Document');
	
	is_deeply(
		$document->namespaces(),
		{
			dc       => 'http://purl.org/dc/elements/1.1/',
			cc       => 'http://web.resource.org/cc/',
			rdf      => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
			inkscape => 'http://www.inkscape.org/namespaces/inkscape',
			sodipodi => 'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd',
			xlink    => 'http://www.w3.org/1999/xlink',
			default  => 'http://www.w3.org/2000/svg',
		},
		'SVG namespaces'
	);
	
	my $count;
	my @nodes;
	
	# Find a existing node set
	$count = $document->findnodes('//default:text');
	is($count, 12, 'Count for SVG text elements');


	# Get some text strings
	@nodes = $document->findnodes('//default:text/default:tspan/text()');
	is_deeply(
		[ map { $_->nodeValue } @nodes ],
		[
			'<svg version="1.0" xml>',
			'<defs>',
			'<use xlink:href="#box_gr',
			'<use xlink:href="#circle',
			'<!--add more content-->',
			'<linearGradient x1="99.7"',
			'<?xml version="1.0"en>',
			'</defs>',
			'<circle cx1="90" r="4" ',
			'</svg>',
			'<use xlink:href="#circle',
			'<line x1="100" y1="300"',
		],
		'Reading SVG text elements'
	);

	
	# Mix various namespaces
	@nodes = $document->findnodes('//default:svg/default:metadata/rdf:RDF/cc:Work/dc:type');
	is_deeply(
		[ map { $_->toString } @nodes ],
		[
			'<dc:type id="type87" rdf:resource="http://purl.org/dc/dcmitype/StillImage"/>',
		],
		'Mixing namespaces in SVG'
	);
}
