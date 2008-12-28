package Xacobeo::XS;

use strict;
use warnings;

use base 'DynaLoader';
use Gtk2;
use XML::LibXML;

our $VERSION = '0.05_01';

sub dl_load_flags {0x01};
__PACKAGE__->bootstrap;

1;
