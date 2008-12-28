#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <gtk2perl.h>

#include "code.h"
#include "libxml.h"


MODULE = Xacobeo::XS		PACKAGE = Xacobeo::XS		


void
xacobeo_populate_gtk_text_buffer(buffer, node, namespaces)
	GtkTextBuffer  *buffer
	xmlNodePtr     node
	HV             *namespaces


void
populate_treeview(treeview, node, namespaces)
	GtkTreeView  *treeview
	xmlNodePtr    node
	HV           *namespaces
