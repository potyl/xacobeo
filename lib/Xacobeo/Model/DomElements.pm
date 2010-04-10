package Xacobeo::Model::DomElements;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Carp;
use Data::Dumper;

use Xacobeo::GObject;


Xacobeo::GObject->register_package('Glib::Object' =>
	interfaces => [ 'Gtk2::TreeModel' ],
	properties => [
		Glib::ParamSpec->scalar(
			'node',
			"Node",
			"The maind node",
			['readable', 'writable', 'construct-only'],
		),
		Glib::ParamSpec->scalar(
			'stamp',
			"Stamp",
			"The maind node",
			['readable', 'writable', 'construct-only'],
		),
	],
);


sub new {
	my $class = shift;
	my ($node) = @_ or croak "Usage: ${class}->new(node)";

	my $self = $class->SUPER::new(
		node  => $node,
		stamp => 1001,#int(rand (1<<31)),
	);

	return $self;
}


sub GET_FLAGS {
#	print "GET_FLAGS\n";
	return [ 'iters-persist' ]
}

sub GET_N_COLUMNS {
#	print "GET_N_COLUMNS\n";
	return 1;
}

sub GET_COLUMN_TYPE {
#	print "GET_COLUMN_TYPE\n";
	return 'Glib::String';
}


sub GET_ITER {
	my ($self, $path) = @_;
	printf "Get iter called for %s\n", $path->to_string;
	printf "Get indices: %s\n", join "/", $path->get_indices;
	my $xpath = join '/', map { sprintf "*[%d]", $_ + 1 } split /:/, $path->to_string;
#	$xpath = "/$xpath";
	print "GET_ITER XPath: $xpath\n";
	
	return [ $self->stamp, 10, { pos => $xpath }, undef ]; # Adding a node here makes a Segmentation fault
}


sub GET_PATH {
	my ($self, $iter) = @_;
	my $path = Gtk2::TreePath->new();
	
	my $node = $self->node->find($iter->[1]);
	print "GET_PATH: \n";
	my @indexes;
	for (; $node; $node = $node->parent) {
		my $index = 0;
		for (my $inode = $node->prev; $inode; $inode = $inode->prev) {
			++$index;
			push @indexes, $index;
		}
	}
	
	foreach my $index (reverse @indexes) {
		print "Adding $index\n";
		$path->append_index($index);
	}
	
	return $path;
}

sub GET_VALUE {
	my ($self, $iter, $column) = @_;
	print "====GET_VALUE ", Dumper($iter), " at $column\n";
	return "aa $column";
}


sub ITER_NEXT {
	my ($self, $iter) = @_;
	print "Called ITER_NEXT: ", Dumper($iter);
	return undef;
}

sub ITER_CHILDREN {
	print "Called ITER_CHILDREN @_\n";
	return undef;
}

sub ITER_HAS_CHILD {
	my ($self, $iter) = @_;
	print "Called ITER_HAS_CHILD: ", Dumper($iter);
	if ($iter->[1] == 0) {
		#return TRUE;
	}
	return FALSE;

}

sub ITER_N_CHILDREN {
	my ($self, $iter) = @_;
	print "Called ITER_N_CHILDREN @_\n";
	# special case: if iter == NULL, return number of top-level rows
	return ( $iter? 0 : 0 );
}

sub ITER_NTH_CHILD {
	print "Called ITER_NTH_CHILD @_\n";
	return undef;
}

sub ITER_PARENT {
	print "Called ITER_PARENT @_\n";
	return FALSE;
}


sub iter_to_node {
	my ($self, $iter) = @_;
	return $self->node;
}


1;
