#include "custom-dom.h"
#include "logger.h"

#define NODE_NAME(node) (node) ? (const char *) (((xmlNode*) node)->name) : "(NULL node)"
#define BOOL(v) (v) ? "TRUE" : "FALSE"

/* boring declarations of local functions */

static void         custom_dom_init            (CustomDom      *pkg_tree);

static void         custom_dom_class_init      (CustomDomClass *klass);

static void         custom_dom_tree_model_init (GtkTreeModelIface *iface);

static void         custom_dom_finalize        (GObject           *object);

static GtkTreeModelFlags custom_dom_get_flags  (GtkTreeModel      *tree_model);

static gint         custom_dom_get_n_columns   (GtkTreeModel      *tree_model);

static GType        custom_dom_get_column_type (GtkTreeModel      *tree_model,
                                                 gint               index);

static gboolean     custom_dom_get_iter        (GtkTreeModel      *tree_model,
                                                 GtkTreeIter       *iter,
                                                 GtkTreePath       *path);

static GtkTreePath *custom_dom_get_path        (GtkTreeModel      *tree_model,
                                                 GtkTreeIter       *iter);

static void         custom_dom_get_value       (GtkTreeModel      *tree_model,
                                                 GtkTreeIter       *iter,
                                                 gint               column,
                                                 GValue            *value);

static gboolean     custom_dom_iter_next       (GtkTreeModel      *tree_model,
                                                 GtkTreeIter       *iter);

static gboolean     custom_dom_iter_children   (GtkTreeModel      *tree_model,
                                                 GtkTreeIter       *iter,
                                                 GtkTreeIter       *parent);

static gboolean     custom_dom_iter_has_child  (GtkTreeModel      *tree_model,
                                                 GtkTreeIter       *iter);

static gint         custom_dom_iter_n_children (GtkTreeModel      *tree_model,
                                                 GtkTreeIter       *iter);

static gboolean     custom_dom_iter_nth_child  (GtkTreeModel      *tree_model,
                                                 GtkTreeIter       *iter,
                                                 GtkTreeIter       *parent,
                                                 gint               n);

static gboolean     custom_dom_iter_parent     (GtkTreeModel      *tree_model,
                                                 GtkTreeIter       *iter,
                                                 GtkTreeIter       *child);



static GObjectClass *parent_class = NULL;  /* GObject stuff - nothing to worry about */


/*****************************************************************************
 *
 *  custom_dom_get_type: here we register our new type and its interfaces
 *                        with the type system. If you want to implement
 *                        additional interfaces like GtkTreeSortable, you
 *                        will need to do it here.
 *
 *****************************************************************************/

GType
custom_dom_get_type (void)
{
  static GType custom_dom_type = 0;

  /* Some boilerplate type registration stuff */
  if (custom_dom_type == 0)
  {
    static const GTypeInfo custom_dom_info =
    {
      sizeof (CustomDomClass),
      NULL,                                         /* base_init */
      NULL,                                         /* base_finalize */
      (GClassInitFunc) custom_dom_class_init,
      NULL,                                         /* class finalize */
      NULL,                                         /* class_data */
      sizeof (CustomDom),
      0,                                           /* n_preallocs */
      (GInstanceInitFunc) custom_dom_init
    };
    static const GInterfaceInfo tree_model_info =
    {
      (GInterfaceInitFunc) custom_dom_tree_model_init,
      NULL,
      NULL
    };

    /* First register the new derived type with the GObject type system */
    custom_dom_type = g_type_register_static (G_TYPE_OBJECT, "CustomDom",
                                               &custom_dom_info, (GTypeFlags)0);

    /* Now register our GtkTreeModel interface with the type system */
    g_type_add_interface_static (custom_dom_type, GTK_TYPE_TREE_MODEL, &tree_model_info);
  }

  return custom_dom_type;
}


/*****************************************************************************
 *
 *  custom_dom_class_init: more boilerplate GObject/GType stuff.
 *                          Init callback for the type system,
 *                          called once when our new class is created.
 *
 *****************************************************************************/

static void
custom_dom_class_init (CustomDomClass *klass)
{
  GObjectClass *object_class;

  parent_class = (GObjectClass*) g_type_class_peek_parent (klass);
  object_class = (GObjectClass*) klass;

  object_class->finalize = custom_dom_finalize;
}

/*****************************************************************************
 *
 *  custom_dom_tree_model_init: init callback for the interface registration
 *                               in custom_dom_get_type. Here we override
 *                               the GtkTreeModel interface functions that
 *                               we implement.
 *
 *****************************************************************************/

static void
custom_dom_tree_model_init (GtkTreeModelIface *iface)
{
  iface->get_flags       = custom_dom_get_flags;
  iface->get_n_columns   = custom_dom_get_n_columns;
  iface->get_column_type = custom_dom_get_column_type;
  iface->get_iter        = custom_dom_get_iter;
  iface->get_path        = custom_dom_get_path;
  iface->get_value       = custom_dom_get_value;
  iface->iter_next       = custom_dom_iter_next;
  iface->iter_children   = custom_dom_iter_children;
  iface->iter_has_child  = custom_dom_iter_has_child;
  iface->iter_n_children = custom_dom_iter_n_children;
  iface->iter_nth_child  = custom_dom_iter_nth_child;
  iface->iter_parent     = custom_dom_iter_parent;
}


/*****************************************************************************
 *
 *  custom_dom_init: this is called everytime a new custom list object
 *                    instance is created (we do that in custom_dom_new).
 *                    Initialise the list structure's fields here.
 *
 *****************************************************************************/

static void
custom_dom_init (CustomDom *custom_dom)
{
  custom_dom->n_columns       = CUSTOM_DOM_N_COLUMNS;

  custom_dom->column_types[0] = G_TYPE_POINTER;  /* CUSTOM_DOM_COL_RECORD    */
  custom_dom->column_types[1] = G_TYPE_STRING;   /* CUSTOM_DOM_COL_NAME      */

  g_assert (CUSTOM_DOM_N_COLUMNS == 2);

  custom_dom->stamp = g_random_int();  /* Random int to check whether an iter belongs to our model */

}


/*****************************************************************************
 *
 *  custom_dom_finalize: this is called just before a custom list is
 *                        destroyed. Free dynamically allocated memory here.
 *
 *****************************************************************************/

static void
custom_dom_finalize (GObject *object)
{
/*  CustomDom *custom_dom = CUSTOM_DOM(object); */

  /* free all records and free all memory used by the list */
  //#warning IMPLEMENT

  /* must chain up - finalize parent */
  (* parent_class->finalize) (object);
}


/*****************************************************************************
 *
 *  custom_dom_get_flags: tells the rest of the world whether our tree model
 *                         has any special characteristics. In our case,
 *                         we have a list model (instead of a tree), and each
 *                         tree iter is valid as long as the row in question
 *                         exists, as it only contains a pointer to our struct.
 *
 *****************************************************************************/

static GtkTreeModelFlags
custom_dom_get_flags (GtkTreeModel *tree_model)
{
  g_return_val_if_fail (CUSTOM_IS_DOM(tree_model), (GtkTreeModelFlags)0);

  return (GTK_TREE_MODEL_ITERS_PERSIST);
}


/*****************************************************************************
 *
 *  custom_dom_get_n_columns: tells the rest of the world how many data
 *                             columns we export via the tree model interface
 *
 *****************************************************************************/

static gint
custom_dom_get_n_columns (GtkTreeModel *tree_model)
{
  g_return_val_if_fail (CUSTOM_IS_DOM(tree_model), 0);

  return CUSTOM_DOM(tree_model)->n_columns;
}


/*****************************************************************************
 *
 *  custom_dom_get_column_type: tells the rest of the world which type of
 *                               data an exported model column contains
 *
 *****************************************************************************/

static GType
custom_dom_get_column_type (GtkTreeModel *tree_model,
                             gint          index)
{
  g_return_val_if_fail (CUSTOM_IS_DOM(tree_model), G_TYPE_INVALID);
  g_return_val_if_fail (index < CUSTOM_DOM(tree_model)->n_columns && index >= 0, G_TYPE_INVALID);

  return CUSTOM_DOM(tree_model)->column_types[index];
}


/*****************************************************************************
 *
 *  custom_dom_get_iter: converts a tree path (physical position) into a
 *                        tree iter structure (the content of the iter
 *                        fields will only be used internally by our model).
 *                        We simply store a pointer to our CustomRecord
 *                        structure that represents that row in the tree iter.
 *
 *****************************************************************************/

static gboolean
custom_dom_get_iter (GtkTreeModel *tree_model,
                      GtkTreeIter  *iter,
                      GtkTreePath  *path)
{
  CustomDom    *custom_dom;
  xmlNode      *node;
  gint         *indices, depth;

  g_assert(CUSTOM_IS_DOM(tree_model));
  g_assert(path!=NULL);

  custom_dom = CUSTOM_DOM(tree_model);

  indices = gtk_tree_path_get_indices(path);
  depth   = gtk_tree_path_get_depth(path);

  node = custom_dom->node;
	for (gint i = 0; i < depth; ++i) {

		if (i) {
			if (node->children) {
				node = node->children;
			}
			else {
				WARN("No more children!");
				return FALSE;
			}
		}

		gint n = indices[i];
		for (gint j = 0; j < n; ++j) {
			if (node->next) {
				node = node->next;
			}
			else {
				WARN("Looping too far!");
				return FALSE;
			}
		}
	}
	INFO("get_iter for %s is %s", gtk_tree_path_to_string(path), NODE_NAME(node));
  g_assert(node != NULL);

  /* We simply store a pointer to our custom record in the iter */
  iter->stamp      = custom_dom->stamp;
  iter->user_data  = node;
  iter->user_data2 = NULL;   /* unused */
  iter->user_data3 = NULL;   /* unused */
  return TRUE;
}


/*****************************************************************************
 *
 *  custom_dom_get_path: converts a tree iter into a tree path (ie. the
 *                        physical position of that row in the list).
 *
 *****************************************************************************/

static GtkTreePath *
custom_dom_get_path (GtkTreeModel *tree_model,
                      GtkTreeIter  *iter)
{
  GtkTreePath  *path;
  xmlNode  *node;
  CustomDom   *custom_dom;

  g_return_val_if_fail (CUSTOM_IS_DOM(tree_model), NULL);
  g_return_val_if_fail (iter != NULL,               NULL);
  g_return_val_if_fail (iter->user_data != NULL,    NULL);

  custom_dom = CUSTOM_DOM(tree_model);

  node = (xmlNode*) iter->user_data;
	
	if (node == NULL) {
		return NULL;
	}

  path = gtk_tree_path_new();
	for (; node; node = node->parent) {
		
		if (node == custom_dom->node) {
			// We've reached our root node
	  	gtk_tree_path_prepend_index(path, 0);
			break;
		}
		
		size_t pos = 0;
		for (xmlNode *cur = node->prev; cur; cur = cur->prev) {
			++pos;
		}
	  gtk_tree_path_prepend_index(path, 0);
	}
	INFO("get_path for %s is %s", NODE_NAME(iter->user_data), gtk_tree_path_to_string(path));

  return path;
}


/*****************************************************************************
 *
 *  custom_dom_get_value: Returns a row's exported data columns
 *                         (_get_value is what gtk_tree_model_get uses)
 *
 *****************************************************************************/

static void
custom_dom_get_value (GtkTreeModel *tree_model,
                       GtkTreeIter  *iter,
                       gint          column,
                       GValue       *value)
{
  xmlNode  *node;
  CustomDom    *custom_dom;

  g_return_if_fail (CUSTOM_IS_DOM (tree_model));
  g_return_if_fail (iter != NULL);
  g_return_if_fail (column < CUSTOM_DOM(tree_model)->n_columns);

  g_value_init (value, CUSTOM_DOM(tree_model)->column_types[column]);

  custom_dom = CUSTOM_DOM(tree_model);

  node = (xmlNode*) iter->user_data;

  g_return_if_fail ( node != NULL );

  switch(column)
  {
    case CUSTOM_DOM_COL_RECORD:
      g_value_set_string(value, "gtk-directory");
		break;

		case CUSTOM_DOM_COL_NAME:
		{
			gchar *string = g_strdup_printf("%s (%d)", NODE_NAME(node), node->type);
			g_value_set_string(value, string);
			g_free(string);
		}
		break;
  }
}


/*****************************************************************************
 *
 *  custom_dom_iter_next: Takes an iter structure and sets it to point
 *                         to the next row.
 *
 *****************************************************************************/

static gboolean
custom_dom_iter_next (GtkTreeModel  *tree_model,
                       GtkTreeIter   *iter)
{
  xmlNode  *node, *next_node;
  CustomDom    *custom_dom;

  g_return_val_if_fail (CUSTOM_IS_DOM (tree_model), FALSE);

  if (iter == NULL || iter->user_data == NULL)
    return FALSE;

  custom_dom = CUSTOM_DOM(tree_model);

  node = (xmlNode *) iter->user_data;
  next_node = node->next;
	INFO("iter_next for %s is %s", NODE_NAME(node), NODE_NAME(next_node));

  /* Is this the last record in the list? */
  if (next_node == NULL)
    return FALSE;

  iter->stamp     = custom_dom->stamp;
  iter->user_data = next_node;

  return TRUE;
}


/*****************************************************************************
 *
 *  custom_dom_iter_children: Returns TRUE or FALSE depending on whether
 *                             the row specified by 'parent' has any children.
 *                             If it has children, then 'iter' is set to
 *                             point to the first child. Special case: if
 *                             'parent' is NULL, then the first top-level
 *                             row should be returned if it exists.
 *
 *****************************************************************************/

static gboolean
custom_dom_iter_children (GtkTreeModel *tree_model,
                           GtkTreeIter  *iter,
                           GtkTreeIter  *parent)
{
  CustomDom  *custom_dom;

//  g_return_val_if_fail (parent == NULL || parent->user_data != NULL, FALSE);
  g_return_val_if_fail (CUSTOM_IS_DOM (tree_model), FALSE);

  custom_dom = CUSTOM_DOM(tree_model);

  /* this is a list, nodes have no children */
	if (parent) {
		iter->stamp = custom_dom->stamp;
		xmlNode *node = (xmlNode *) parent->user_data;
		if (node == NULL) {
			WARN("Broken parent iter is missing its xml node");
			return FALSE;
		}
		iter->user_data = node->children;
		INFO("Child of %s is %s", NODE_NAME(node), NODE_NAME(node->children));
		return iter->user_data ? TRUE : FALSE;
	}

  /* parent == NULL is a special case; we need to return the first top-level row */


  /* No rows => no first row */
  if (custom_dom->node == NULL)
    return FALSE;

  /* Set iter to first item in list */
  iter->stamp     = custom_dom->stamp;
  iter->user_data = custom_dom->node;

  return TRUE;
}


/*****************************************************************************
 *
 *  custom_dom_iter_has_child: Returns TRUE or FALSE depending on whether
 *                              the row specified by 'iter' has any children.
 *
 *****************************************************************************/

static gboolean
custom_dom_iter_has_child (GtkTreeModel *tree_model,
                            GtkTreeIter  *iter)
{
	xmlNode *node = (xmlNode *) iter->user_data;
	INFO("node %s has children? %d", BOOL(node->children));
  return node->children ? TRUE : FALSE;
}


/*****************************************************************************
 *
 *  custom_dom_iter_n_children: Returns the number of children the row
 *                               specified by 'iter' has. This is usually 0,
 *                               as we only have a list and thus do not have
 *                               any children to any rows. A special case is
 *                               when 'iter' is NULL, in which case we need
 *                               to return the number of top-level nodes,
 *                               ie. the number of rows in our list.
 *
 *****************************************************************************/

static gint
custom_dom_iter_n_children (GtkTreeModel *tree_model,
                             GtkTreeIter  *iter)
{
  CustomDom  *custom_dom;

  g_return_val_if_fail (CUSTOM_IS_DOM (tree_model), -1);
  g_return_val_if_fail (iter == NULL || iter->user_data != NULL, FALSE);

  custom_dom = CUSTOM_DOM(tree_model);
	
	if (iter == NULL) {
		INFO("n_children of root is %d", custom_dom->node ? 1 : 0);
		return custom_dom->node ? 1 : 0;
	}
	
	xmlNode *node = (xmlNode *) iter->user_data;
	
	size_t count = 0;
	if (node) {
		for (node = node->children; node; node = node->next) {
			++count;
		}
	}
	
	INFO("n_children of %s is %d", NODE_NAME(node), count);
	
  return count;
}


/*****************************************************************************
 *
 *  custom_dom_iter_nth_child: If the row specified by 'parent' has any
 *                              children, set 'iter' to the n-th child and
 *                              return TRUE if it exists, otherwise FALSE.
 *                              A special case is when 'parent' is NULL, in
 *                              which case we need to set 'iter' to the n-th
 *                              row if it exists.
 *
 *****************************************************************************/

static gboolean
custom_dom_iter_nth_child (GtkTreeModel *tree_model,
                            GtkTreeIter  *iter,
                            GtkTreeIter  *parent,
                            gint          n)
{
  xmlNode      *node;
  CustomDom    *custom_dom;

  g_return_val_if_fail (CUSTOM_IS_DOM (tree_model), FALSE);

  custom_dom = CUSTOM_DOM(tree_model);

  if (parent == NULL) {
    // The top parent can have either a single node or none
		if (n == 0 && custom_dom->node) {
			iter->stamp = custom_dom->stamp;
			iter->user_data = custom_dom->node;
			return TRUE;
		}
		
		WARN("Asking for the n(%d) child of parent, but we can't", n);
		return FALSE;
	}

  node = (xmlNode *) parent->user_data;
	if (node == NULL || node->children == NULL) {return FALSE;}
	
	node = node->children;
	for (size_t i = 0; i < n; ++i) {
		node = node->next;
		if (node == NULL) {
			WARN("Can't find the requested n(%d) child as %d is the last", n, i);
			return FALSE;
		}
	}

  iter->stamp = custom_dom->stamp;
  iter->user_data = node;
	INFO("nth_child(%d) of %s is %s", n, NODE_NAME(parent->user_data), NODE_NAME(node));

  return TRUE;
}


/*****************************************************************************
 *
 *  custom_dom_iter_parent: Point 'iter' to the parent node of 'child'. As
 *                           we have a list and thus no children and no
 *                           parents of children, we can just return FALSE.
 *
 *****************************************************************************/

static gboolean
custom_dom_iter_parent (GtkTreeModel *tree_model,
                         GtkTreeIter  *iter,
                         GtkTreeIter  *child)
{
  xmlNode      *node;
  CustomDom    *custom_dom;

  g_return_val_if_fail (CUSTOM_IS_DOM (tree_model), FALSE);

  custom_dom = CUSTOM_DOM(tree_model);

	node = (xmlNode *) child->user_data;
	if (node == NULL) {
		WARN("Node is null; can't find a parent");
		return FALSE;
	}
	
	INFO("Parent of %s is %s", NODE_NAME(node), NODE_NAME(node->parent));
	
  iter->stamp = custom_dom->stamp;
  iter->user_data = node->parent;
	
	return TRUE;
}


/*****************************************************************************
 *
 *  custom_dom_new:  This is what you use in your own code to create a
 *                    new custom list tree model for you to use.
 *
 *****************************************************************************/

CustomDom *
custom_dom_new (xmlNode *node)
{
  CustomDom *object;

  object = (CustomDom*) g_object_new (CUSTOM_TYPE_DOM, NULL);
  g_assert( object != NULL );

	object->node = node;

  return object;
}
