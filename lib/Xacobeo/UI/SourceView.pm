package Xacobeo::UI::SourceView;

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Pango qw(PANGO_WEIGHT_LIGHT PANGO_WEIGHT_BOLD);
use Gtk2::SourceView2;

use Glib::Object::Subclass 'Gtk2::SourceView2::View';

# The tag table shared by all editors
my $TAG_TABLE = _create_tag_table(Gtk2::TextTagTable->new());


sub INIT_INSTANCE {
	my $self = shift;
	my $buffer = _create_buffer();
	$self->set_buffer($buffer);
}


sub _create_buffer {
	my $buffer = Gtk2::SourceView2::Buffer->new($TAG_TABLE);
	$buffer->set_highlight_syntax(undef);

	# This will disable the undo/redo forever
	$buffer->begin_not_undoable_action();
	
	return $buffer;
}


#
# Creates the text tag table shared by all source views.
#
sub _create_tag_table {
	my $tag_table = Gtk2::TextTagTable->new();

	_add_tag($tag_table, result_count =>
		family     => 'Courier 10 Pitch',
		background => '#EDE9E3',
		foreground => 'black',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT
	);

	# Make the boolean and number look a like
	foreach my $name qw(boolean number) {
		_add_tag($tag_table, $name =>
			family     => 'Courier 10 Pitch',
			foreground => 'black',
			weight     => PANGO_WEIGHT_BOLD
		);
	}

	_add_tag($tag_table, attribute_name =>
		foreground => 'red',
	);

	_add_tag($tag_table, attribute_value =>
		foreground => 'blue',
	);

	_add_tag($tag_table, comment =>
		foreground => '#008000',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT,
	);

	_add_tag($tag_table, dtd =>
		foreground => '#558CBA',
		style      => 'italic',
	);

	_add_tag($tag_table, element =>
		foreground => '#800080',
		weight     => PANGO_WEIGHT_BOLD,
	);

	_add_tag($tag_table, pi =>
		foreground => '#558CBA',
		style      => 'italic',
	);

	_add_tag($tag_table, pi_data =>
		foreground => 'red',
		style      => 'italic',
	);

	_add_tag($tag_table, syntax =>
		foreground => 'black',
		weight     => PANGO_WEIGHT_BOLD,
	);

	_add_tag($tag_table, literal =>
		foreground => 'black',
	);

	_add_tag($tag_table, cdata =>
		foreground => 'red',
		weight     => PANGO_WEIGHT_BOLD
	);

	_add_tag($tag_table, cdata_content =>
		foreground => 'purple',
		weight     => PANGO_WEIGHT_LIGHT,
		style      => 'italic',
	);

	_add_tag($tag_table, namespace_name =>
		foreground => 'red',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT,
	);

	_add_tag($tag_table, namespace_uri =>
		foreground => 'blue',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT,
	);

	_add_tag($tag_table, entity_ref =>
		foreground => 'red',
		style      => 'italic',
		weight     => PANGO_WEIGHT_BOLD,
	);

	_add_tag($tag_table, error =>
		foreground => 'red',
	);

	_add_tag($tag_table, selected =>
		background => 'yellow',
	);

	return $tag_table;
}


#
# Creates a text tag (Gtk2::TextTag) with the given name and properties and adds
# it to the given tag table.
#
sub _add_tag {
	my ($tag_table, $name, @properties) = @_;
	my $tag = Gtk2::TextTag->new($name);
	$tag->set(@properties);
	$tag_table->add($tag);
}


1;
