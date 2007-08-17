[CCode (cprefix = "Glade", lower_case_cprefix = "glade_")]
namespace Glade {
	[CCode (cheader_filename = "glade/glade.h")]
	public class XML : GLib.Object {
		public weak Gtk.Widget build_widget (Glade.WidgetInfo info);
		public bool @construct (string fname, string root, string domain);
		public bool construct_from_buffer (string buffer, int size, string root, string domain);
		public weak Gtk.AccelGroup ensure_accel ();
		public static GLib.Type get_type ();
		public weak Gtk.Widget get_widget (string name);
		public weak GLib.List get_widget_prefix (string name);
		public void handle_internal_child (Gtk.Widget parent, Glade.ChildInfo child_info);
		public void handle_widget_prop (Gtk.Widget widget, string prop_name, string value_name);
		public XML (string fname, string root, string domain);
		public XML.from_buffer (string buffer, int size, string root, string domain);
		public weak string relative_file (string filename);
		public void set_common_params (Gtk.Widget widget, Glade.WidgetInfo info);
		public void set_packing_property (Gtk.Widget parent, Gtk.Widget child, string name, string value);
		public void set_toplevel (Gtk.Window window);
		public bool set_value_from_string (GLib.ParamSpec pspec, string string, GLib.Value value);
		public void signal_autoconnect ();
		public void signal_autoconnect_full (Glade.XMLConnectFunc func, pointer user_data);
		public void signal_connect (string handlername, GLib.Callback func);
		public void signal_connect_data (string handlername, GLib.Callback func, pointer user_data);
		public void signal_connect_full (string handler_name, Glade.XMLConnectFunc func, pointer user_data);
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct AccelInfo {
		public uint key;
		public Gdk.ModifierType modifiers;
		public weak string signal_name;
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct AtkActionInfo {
		public weak string action_name;
		public weak string description;
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct AtkRelationInfo {
		public weak string target;
		public weak string type;
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct ChildInfo {
		public weak Glade.Property properties;
		public uint n_properties;
		public weak Glade.WidgetInfo child;
		public weak string internal_child;
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct Interface {
		public weak string requires;
		public uint n_requires;
		public weak Glade.WidgetInfo toplevels;
		public uint n_toplevels;
		public weak GLib.HashTable names;
		public weak GLib.HashTable strings;
		public void destroy ();
		public void dump (string filename);
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct Property {
		public weak string name;
		public weak string value;
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct SignalInfo {
		public weak string name;
		public weak string handler;
		public weak string object;
		public uint after;
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct WidgetInfo {
		public weak Glade.WidgetInfo parent;
		public weak string classname;
		public weak string name;
		public weak Glade.Property properties;
		public uint n_properties;
		public weak Glade.Property atk_props;
		public uint n_atk_props;
		public weak Glade.SignalInfo signals;
		public uint n_signals;
		public weak Glade.AtkActionInfo atk_actions;
		public uint n_atk_actions;
		public weak Glade.AtkRelationInfo relations;
		public uint n_relations;
		public weak Glade.AccelInfo accels;
		public uint n_accels;
		public weak Glade.ChildInfo children;
		public uint n_children;
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct Parser {
		public static weak Glade.Interface parse_buffer (string buffer, int len, string domain);
		public static weak Glade.Interface parse_file (string file, string domain);
	}
	[ReferenceType]
	[CCode (cheader_filename = "glade/glade.h")]
	public struct Standard {
		public void build_children (Gtk.Widget parent, Glade.WidgetInfo info);
		public static weak Gtk.Widget build_widget (Glade.XML xml, GLib.Type widget_type, Glade.WidgetInfo info);
	}
	public static delegate void ApplyCustomPropFunc (Glade.XML xml, Gtk.Widget widget, string propname, string value);
	public static delegate void BuildChildrenFunc (Glade.XML xml, Gtk.Widget parent, Glade.WidgetInfo info);
	public static delegate weak Gtk.Widget FindInternalChildFunc (Glade.XML xml, Gtk.Widget parent, string childname);
	public static delegate weak Gtk.Widget NewFunc (Glade.XML xml, GLib.Type widget_type, Glade.WidgetInfo info);
	public static delegate void XMLConnectFunc (string handler_name, GLib.Object object, string signal_name, string signal_data, GLib.Object connect_object, bool after, pointer user_data);
	public static delegate weak Gtk.Widget XMLCustomWidgetHandler (Glade.XML xml, string func_name, string name, string string1, string string2, int int1, int int2, pointer user_data);
	public static int enum_from_string (GLib.Type type, string string);
	public static uint flags_from_string (GLib.Type type, string string);
	public static weak string get_widget_name (Gtk.Widget widget);
	public static weak Glade.XML get_widget_tree (Gtk.Widget widget);
	public static weak string module_check_version (int version);
	public static void register_custom_prop (GLib.Type type, string prop_name, Glade.ApplyCustomPropFunc apply_prop);
	public static void register_widget (GLib.Type type, Glade.NewFunc new_func, Glade.BuildChildrenFunc build_children, Glade.FindInternalChildFunc find_internal_child);
	public static void set_custom_handler (Glade.XMLCustomWidgetHandler handler, pointer user_data);
}
