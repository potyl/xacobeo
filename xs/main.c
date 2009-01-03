//
// Sample program that displays an XML file in a GtkTextView.
// 
// Copyright (C) 2008 Emmanuel Rodriguez
//
// This program is free software; you can redistribute it and/or modify it under
// the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
// any later version of Perl 5 you may have available.
//
//

#include "code.h"
#include "logger.h"
#include <glib/gprintf.h>

#define TAG(name, ...) gtk_text_buffer_create_tag(buffer, name, __VA_ARGS__, NULL)


static void       my_create_buffer_tags (GtkTextBuffer *buffer);
static void       my_create_widgets     (GtkTextView **textview, GtkTreeView **treeview);
static GtkWidget* my_create_textview    (void);
static GtkWidget* my_create_treeview    (void);
static GtkWidget* my_wrap_in_scrolls    (GtkWidget *widget);


int main (int argc, char **argv) {

	// Parse the arguments
	gtk_init(&argc, &argv);
	
	if (argc < 2) {
		g_printf("Usage: %s file [quit]\n", argv[0]);
		return 1;
	}
	char *filename = argv[1];

	// Load the XML document
	DEBUG("Reading file %s", filename);
	xmlDoc *document = xmlReadFile(filename, NULL, 0);
	INFO("Read file %s", filename);
	if (document == NULL) {
		g_printf("Failed to parse %s\n", filename);
		return 1;
	}

	// Render the XML document
	GtkTextView *textview = NULL;
	GtkTreeView *treeview = NULL;
	
	my_create_widgets(&textview, &treeview);
	
	// Fill the TextView (it's faster to remove the buffer and to put it back)
	GtkTextBuffer *buffer = gtk_text_view_get_buffer(textview);
	gtk_text_view_set_buffer(textview, NULL);
	xacobeo_populate_gtk_text_buffer(buffer, (xmlNode *) document, NULL);
	gtk_text_view_set_buffer(textview, buffer);

	// Scroll to the beginning of the text
	GtkTextIter iter;
	gtk_text_buffer_get_start_iter(buffer, &iter);
	gtk_text_view_scroll_to_iter(textview, &iter, 0.0, FALSE, 0.0, 0.0); 
	
	GtkTreeStore *store = GTK_TREE_STORE(gtk_tree_view_get_model(treeview));
	gtk_tree_view_set_model(treeview, NULL);
	gtk_tree_store_clear(store);
	xacobeo_populate_gtk_tree_store(store, (xmlNode *) document, NULL);
	gtk_tree_view_set_model(treeview, GTK_TREE_MODEL(store));
	xmlFreeDoc(document);
	

	// If we just want to time the execution time we don't need an event loop
	if (! (argc > 2 && strcmp("quit", argv[2]) == 0) ) {
		// Main event loop
		gtk_main();
	}
	
	xmlCleanupParser();

	return 0;
}


//
// Creates the main widgets and prepares them for displaying. This function
// returns the GtkTextView casted as a GtkWidget.
//
static void my_create_widgets (GtkTextView **prt_textview, GtkTreeView **prt_treeview) {
	
	// The main widgets
	GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	GtkWidget *textview = my_create_textview();
	GtkWidget *treeview = my_create_treeview();

	
	// Pack the widgets together
	GtkWidget *pane = gtk_hpaned_new();
	gtk_paned_set_position(GTK_PANED(pane), 200);
	gtk_paned_add1(GTK_PANED(pane), my_wrap_in_scrolls(treeview));
	gtk_paned_add2(GTK_PANED(pane), my_wrap_in_scrolls(textview));

	gtk_container_add(GTK_CONTAINER(window), pane);
	gtk_widget_show_all(window);
	
	
	// Connect the signals
	g_signal_connect(G_OBJECT(window), "delete_event", G_CALLBACK(gtk_main_quit), NULL);


	// Set the return values
	*prt_textview = GTK_TEXT_VIEW(textview);
	*prt_treeview = GTK_TREE_VIEW(treeview);
}



//
// Creates the text view and sets it's model (text buffer)
//
static GtkWidget* my_create_textview (void) {
	// Prepare the text view
	GtkWidget *textview = gtk_text_view_new();
	GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(textview));
	my_create_buffer_tags(buffer);

	gtk_widget_set_size_request(textview, 600, 400);
	gtk_text_view_set_editable(GTK_TEXT_VIEW(textview), FALSE);
	gtk_text_view_set_cursor_visible(GTK_TEXT_VIEW(textview), FALSE);
	
	return textview;
}



//
// Creates the tree view and sets it's model (tree store)
//
static GtkWidget* my_create_treeview (void) {
	// Prepre the tree view
	GtkWidget *treeview = gtk_tree_view_new();
	GtkTreeStore *store = gtk_tree_store_new(2, G_TYPE_POINTER, G_TYPE_STRING);
	gtk_tree_view_set_model(GTK_TREE_VIEW(treeview), GTK_TREE_MODEL(store));
	

	GtkCellRenderer *cell = gtk_cell_renderer_text_new();
  GtkTreeViewColumn *column = gtk_tree_view_column_new_with_attributes(
		"Element",
		GTK_CELL_RENDERER(cell),
		"text", DOM_COL_ELEMENT_NAME,
// Enable only if there are more than one column!
//		"resizable", TRUE,
//		"sizing", GTK_TREE_VIEW_COLUMN_AUTOSIZE,
		NULL
	);
  gtk_tree_view_insert_column(GTK_TREE_VIEW(treeview), GTK_TREE_VIEW_COLUMN(column), 0);

	return treeview;
}



//
// Wraps the a widget with scroll bars.
//
static GtkWidget* my_wrap_in_scrolls (GtkWidget *widget) {
	GtkWidget *scrolls = gtk_scrolled_window_new(NULL, NULL);
	gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolls), GTK_POLICY_AUTOMATIC, GTK_POLICY_ALWAYS);
	gtk_scrolled_window_set_shadow_type(GTK_SCROLLED_WINDOW(scrolls), GTK_SHADOW_OUT);
	gtk_container_add(GTK_CONTAINER(scrolls), widget);
	return scrolls;
}



//
// Creates the markup rules to use for displaying XML.
//
static void my_create_buffer_tags (GtkTextBuffer *buffer) {

	TAG("result_count", 
		"family",      "Courier 10 Pitch",
		"background",  "#EDE9E3",
		"foreground",  "black",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("boolean", 
			"family",      "Courier 10 Pitch",
			"foreground",  "black",
			"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("number", 
			"family",      "Courier 10 Pitch",
			"foreground",  "black",
			"weight",      PANGO_WEIGHT_BOLD
	);

	TAG("attribute_name", 
		"foreground",  "red"
	);

	TAG("attribute_value", 
		"foreground",  "blue"
	);
	
	TAG("comment", 
		"foreground",  "#008000",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("dtd", 
		"foreground",  "#558CBA",
		"style",       PANGO_STYLE_ITALIC
	);
	
	TAG("element", 
		"foreground",  "#800080",
		"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("pi", 
		"foreground",  "#558CBA",
		"style",       PANGO_STYLE_ITALIC
	);
	
	TAG("pi_data", 
		"foreground",  "red",
		"style",       PANGO_STYLE_ITALIC
	);
	
	TAG("syntax", 
		"foreground",  "black",
		"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("text", 
		"foreground",  "black"
	);
	
	TAG("literal", 
		"foreground",  "black"
	);
	
	TAG("cdata", 
		"foreground",  "red",
		"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("cdata_content", 
		"foreground",  "purple",
		"weight",      PANGO_WEIGHT_BOLD,
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("namespace_name", 
		"foreground",  "red",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("namespace_uri", 
		"foreground",  "blue",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("entity_ref", 
		"foreground",  "red",
		"weight",      PANGO_WEIGHT_BOLD
	);
}
