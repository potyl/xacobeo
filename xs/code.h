#ifndef __XACOBEO_CODE_H__
#define __XACOBEO_CODE_H__


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>
#include <libxml/tree.h>


// The columns in the DOM Tree View
enum DomModelColumns {
	DOM_COL_XML_POINTER,
	DOM_COL_ELEMENT_NAME,
};


// Public prototypes
void xacobeo_populate_gtk_text_buffer (GtkTextBuffer *buffer, xmlNode *node, HV *namespaces);
void populate_treeview                (GtkTreeView *treeview, xmlNode *node, HV *namespaces);


#endif
