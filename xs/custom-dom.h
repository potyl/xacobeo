#ifndef _custom_dom_h_included_
#define _custom_dom_h_included_

#include <gtk/gtk.h>
#include <libxml/tree.h>

/* Some boilerplate GObject defines. 'klass' is used
 *   instead of 'class', because 'class' is a C++ keyword */

#define CUSTOM_TYPE_DOM            (custom_dom_get_type ())
#define CUSTOM_DOM(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), CUSTOM_TYPE_DOM, CustomDom))
#define CUSTOM_DOM_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass),  CUSTOM_TYPE_DOM, CustomDomClass))
#define CUSTOM_IS_DOM(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CUSTOM_TYPE_DOM))
#define CUSTOM_IS_DOM_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass),  CUSTOM_TYPE_DOM))
#define CUSTOM_DOM_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj),  CUSTOM_TYPE_DOM, CustomDomClass))

/* The data columns that we export via the tree model interface */

enum
{
  CUSTOM_DOM_COL_RECORD = 0,
  CUSTOM_DOM_COL_NAME,
  CUSTOM_DOM_N_COLUMNS,
} ;


typedef struct _CustomRecord    CustomRecord;
typedef struct _CustomDom       CustomDom;
typedef struct _CustomDomClass  CustomDomClass;



/* CustomRecord: this structure represents a row */

struct _CustomRecord
{
  xmlNode  *node;

  /* admin stuff used by the custom list model */
  guint     pos;   /* pos within the array */
};



/* CustomDom: this structure contains everything we need for our
 *             model implementation. You can add extra fields to
 *             this structure, e.g. hashtables to quickly lookup
 *             rows or whatever else you might need, but it is
 *             crucial that 'parent' is the first member of the
 *             structure.                                          */

struct _CustomDom
{
  GObject         parent;      /* this MUST be the first member */

  xmlNode  *node;

  /* These two fields are not absolutely necessary, but they    */
  /*   speed things up a bit in our get_value implementation    */
  gint            n_columns;
  GType           column_types[CUSTOM_DOM_N_COLUMNS];

  gint            stamp;       /* Random integer to check whether an iter belongs to our model */
};



/* CustomDomClass: more boilerplate GObject stuff */

struct _CustomDomClass
{
  GObjectClass parent_class;
};


GType custom_dom_get_type (void);
CustomDom *custom_dom_new (xmlNode *node);

#endif /* _custom_dom_h_included_ */
