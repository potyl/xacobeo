package Xacobeo::UI::XPathEntry;

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Ex::Entry::Pango;
use Xacobeo::Accessors qw(document valid);

use Glib::Object::Subclass 'Gtk2::Ex::Entry::Pango' =>
	signals => {
		'xpath-changed' => {
			flags       => ['run-last'],
			# Parameters:   XPath expression isValid
			param_types => ['Glib::String',  'Glib::Boolean'],
		},
	},
;

sub INIT_INSTANCE {
	my $self = shift;

	$self->signal_connect('changed' => \&callback_changed);
	$self->valid(FALSE);
}


sub set_document {
	my $self = shift;
	my ($document) = @_;
	$self->document($document);
}


sub callback_changed {
	my ($self) = @_;

	my $xpath = $self->get_text;
	my $is_valid = FALSE;
	if ($xpath) {
		$is_valid = $self->document->validate($xpath);
		if (! $is_valid) {
			# Mark the XPath expression as wrong
			my $escaped = Glib::Markup::escape_text($xpath);
			my $markup = "<span underline='error' underline_color='red'>$escaped</span>";
			$self->set_markup($markup);
			$self->signal_stop_emission_by_name('changed');
		}
	}

	$self->valid($is_valid);
	$self->signal_emit('xpath-changed' => $xpath, $is_valid);
}


sub is_valid {
	my $self = shift;
	return $self->valid;
}


1;
