/* gstreamer-controller-1.0.vapi generated by vapigen, do not modify. */

[CCode (cprefix = "Gst", gir_namespace = "GstController", gir_version = "1.0", lower_case_cprefix = "gst_")]
namespace Gst {
	namespace Controller {
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstARGBControlBinding", type_id = "gst_argb_control_binding_get_type ()")]
		[GIR (name = "ARGBControlBinding")]
		public class ARGBControlBinding : Gst.ControlBinding {
			[CCode (cname = "gst_argb_control_binding_new", has_construct_function = false, type = "GstControlBinding*")]
			public ARGBControlBinding (Gst.Object object, string property_name, Gst.ControlSource cs_a, Gst.ControlSource cs_r, Gst.ControlSource cs_g, Gst.ControlSource cs_b);
			[NoAccessorMethod]
			public Gst.ControlSource control_source_a { owned get; construct; }
			[NoAccessorMethod]
			public Gst.ControlSource control_source_b { owned get; construct; }
			[NoAccessorMethod]
			public Gst.ControlSource control_source_g { owned get; construct; }
			[NoAccessorMethod]
			public Gst.ControlSource control_source_r { owned get; construct; }
		}
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstDirectControlBinding", type_id = "gst_direct_control_binding_get_type ()")]
		[GIR (name = "DirectControlBinding")]
		public class DirectControlBinding : Gst.ControlBinding {
			[CCode (cname = "gst_direct_control_binding_new", has_construct_function = false, type = "GstControlBinding*")]
			public DirectControlBinding (Gst.Object object, string property_name, Gst.ControlSource cs);
			[NoAccessorMethod]
			public Gst.ControlSource control_source { owned get; construct; }
		}
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstInterpolationControlSource", type_id = "gst_interpolation_control_source_get_type ()")]
		[GIR (name = "InterpolationControlSource")]
		public class InterpolationControlSource : Gst.Controller.TimedValueControlSource {
			[CCode (cname = "gst_interpolation_control_source_new", has_construct_function = false, type = "GstControlSource*")]
			public InterpolationControlSource ();
			[NoAccessorMethod]
			public Gst.Controller.InterpolationMode mode { get; set; }
		}
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstLFOControlSource", type_id = "gst_lfo_control_source_get_type ()")]
		[GIR (name = "LFOControlSource")]
		public class LFOControlSource : Gst.ControlSource {
			[CCode (cname = "gst_lfo_control_source_new", has_construct_function = false, type = "GstControlSource*")]
			public LFOControlSource ();
			[NoAccessorMethod]
			public double amplitude { get; set; }
			[NoAccessorMethod]
			public double frequency { get; set; }
			[NoAccessorMethod]
			public double offset { get; set; }
			[NoAccessorMethod]
			public uint64 timeshift { get; set; }
			[NoAccessorMethod]
			public Gst.Controller.LFOWaveform waveform { get; set; }
		}
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstTimedValueControlSource", type_id = "gst_timed_value_control_source_get_type ()")]
		[GIR (name = "TimedValueControlSource")]
		public abstract class TimedValueControlSource : Gst.ControlSource {
			public weak GLib.Mutex @lock;
			public int nvalues;
			public bool valid_cache;
			public GLib.Sequence<Gst.Controller.ControlPoint?> values;
			[CCode (has_construct_function = false)]
			protected TimedValueControlSource ();
			[CCode (cname = "gst_timed_value_control_source_find_control_point_iter")]
			public unowned GLib.SequenceIter find_control_point_iter (Gst.ClockTime timestamp);
			[CCode (cname = "gst_timed_value_control_source_get_count")]
			public int get_count ();
			[CCode (cname = "gst_timed_value_control_source_set")]
			public bool @set (Gst.ClockTime timestamp, double value);
			[CCode (cname = "gst_timed_value_control_source_unset")]
			public bool unset (Gst.ClockTime timestamp);
			[CCode (cname = "gst_timed_value_control_source_unset_all")]
			public void unset_all ();
		}
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstTriggerControlSource", type_id = "gst_trigger_control_source_get_type ()")]
		[GIR (name = "TriggerControlSource")]
		public class TriggerControlSource : Gst.Controller.TimedValueControlSource {
			[CCode (cname = "gst_trigger_control_source_new", has_construct_function = false, type = "GstControlSource*")]
			public TriggerControlSource ();
			[NoAccessorMethod]
			public int64 tolerance { get; set; }
		}
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstControlPoint", has_type_id = false)]
		[GIR (name = "ControlPoint")]
		public struct ControlPoint {
			public Gst.ClockTime timestamp;
			public double value;
			[CCode (cname = "cache.cubic.h")]
			public double cache_cubic_h;
			[CCode (cname = "cache.cubic.z")]
			public double cache_cubic_z;
		}
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstInterpolationMode", cprefix = "GST_INTERPOLATION_MODE_", type_id = "gst_interpolation_mode_get_type ()")]
		[GIR (name = "InterpolationMode")]
		public enum InterpolationMode {
			NONE,
			LINEAR,
			CUBIC
		}
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstLFOWaveform", cprefix = "GST_LFO_WAVEFORM_", type_id = "gst_lfo_waveform_get_type ()")]
		[GIR (name = "LFOWaveform")]
		public enum LFOWaveform {
			SINE,
			SQUARE,
			SAW,
			REVERSE_SAW,
			TRIANGLE
		}
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstDirectControlBindingConvertGValue", has_target = false)]
		public delegate void DirectControlBindingConvertGValue (Gst.Controller.DirectControlBinding self, double src_value, GLib.Value dest_value);
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "GstDirectControlBindingConvertValue", has_target = false)]
		public delegate void DirectControlBindingConvertValue (Gst.Controller.DirectControlBinding self, double src_value, void* dest_value);
		[CCode (cheader_filename = "gst/controller/gstargbcontrolbinding.h,gst/controller/gstdirectcontrolbinding.h,gst/controller/gstinterpolationcontrolsource.h,gst/controller/gstlfocontrolsource.h,gst/controller/gsttimedvaluecontrolsource.h,gst/controller/gsttriggercontrolsource.h", cname = "gst_timed_value_control_invalidate_cache")]
		public static void timed_value_control_invalidate_cache (Gst.Controller.TimedValueControlSource self);
	}
}
