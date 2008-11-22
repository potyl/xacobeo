#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
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
	
	my $got;
	

	# Look for a non existing node
	$got = $document->find('//x');
	is_deeply(
		$got->size,
		0,
		'Nodes from a non existing element'
	);

	
	# Test that an invalid xpath expression doesn't throw an error
	$got = $document->find('//x/');
	is_deeply(
		$got,
		undef,
		'Nodes from an invalid XPath expression'
	);


	# Find a existing node set
	$got = $document->find('//description[@xml:lang="es"]');
	is($got->size, 461, 'A lot of nodes');
	

	# Fails because the namespace doesn't exist
	$got = $document->find('/x:html//x:a[@href]');
	is($got, undef, 'XPath query uses undefined namespaces');

	
	# Fails because the syntax is invalid
	$got = $document->find('/html//a[@href');
	is($got, undef, 'Invalid XPath syntax');

	
	# Fails because the function aaa() is not defined
	$got = $document->find('aaa(1)');
	is($got, undef, 'Undefined XPath function');

	
	# This is fine
	$got = $document->validate('/xkbConfigRegistry');
	ok($got, 'Validate XPath query');
}



sub test_namespaces {
	my $document = Xacobeo::Document->new("$FOLDER/SVG.svg");
	isa_ok($document, 'Xacobeo::Document');
	
	is_deeply(
		$document->namespaces(),
		{
			'http://purl.org/dc/elements/1.1/'                   => 'dc',
			'http://web.resource.org/cc/'                        => 'cc',
			'http://www.w3.org/1999/02/22-rdf-syntax-ns#'        => 'rdf',
			'http://www.inkscape.org/namespaces/inkscape'        => 'inkscape',
			'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd' => 'sodipodi',
			'http://www.w3.org/1999/xlink'                       => 'xlink',
			'http://www.w3.org/2000/svg'                         => 'default',
		},
		'SVG namespaces'
	);
	
	my $got;
	
	# Find a existing node set
	$got = $document->find('//default:text');
	is($got->size, 12, 'Count for SVG text elements');


	# Get some text strings
	$got = $document->find('//default:text/default:tspan/text()');
	is_deeply(
		[ map { $_->nodeValue } $got->get_nodelist ],
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
	$got = $document->find('//default:svg/default:metadata/rdf:RDF/cc:Work/dc:type');
	is_deeply(
		[ map { $_->toString } $got->get_nodelist ],
		[
			'<dc:type id="type87" rdf:resource="http://purl.org/dc/dcmitype/StillImage"/>',
		],
		'Mixing namespaces in SVG'
	);
}
