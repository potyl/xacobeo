package Xacobeo::UI::XPathEntry;

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Ex::Entry::Pango;
use Xacobeo::I18n;
use Xacobeo::Utils qw(escape_xml_text);
use Xacobeo::Accessors qw(document);

use Glib::Object::Subclass 'Gtk2::Ex::Entry::Pango';


sub INIT_INSTANCE {
	my $self = shift;

	$self->signal_connect('changed' => \&callback_changed);
}


sub set_document {
	my $self = shift;
	my ($document) = @_;
	$self->document($document);
}


sub callback_changed {
	my ($self) = @_;

	my $xpath = $self->get_text;
	my $xpath_valid = FALSE;
	if ($xpath) {
		if ($self->document->validate($xpath)) {
			# The expression is valid
			$xpath_valid = TRUE;
		}
		else {
			# Mark the XPath expression as wrong
			my $escaped = Glib::Markup::escape_text($xpath);
			my $markup = "<span underline='error' underline_color='red'>$escaped</span>";
			$self->set_markup($markup);
			$self->signal_stop_emission_by_name('changed');
		}
	}

	print "FIXME: fire the event xpath-change and include the flag is_valid, this will be used to update the 'Evaluate' button\n";
}


1;
