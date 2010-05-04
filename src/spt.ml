(** The plot hierarchy.

    @author eaburns
    @since 2010-04-23
*)

open Geometry
open Drawing

let default_tick_style =
  (** The default style for the text associated with tick marks on a
      numeric axis. *)
  {
    text_font = "Palatino-Roman";
    text_size = 0.03;
    text_slant = font_slant_normal;
    text_weight = font_weight_normal;
    text_color = black;
  }


let default_legend_style =
  (** The default style for legend text. *)
  {
    text_font = "Palatino-Roman";
    text_size = 0.03;
    text_slant = font_slant_normal;
    text_weight = font_weight_normal;
    text_color = black;
  }

let default_label_style =
  (** The default style for the x and y axis labels and the title
      text. *)
  {
    text_font = "Palatino-Roman";
    text_size = 0.04;
    text_slant = font_slant_normal;
    text_weight = font_weight_normal;
    text_color = black;
  }


let text_padding = 0.02
  (** Padding around text *)


class virtual plot title =
  (** [plot title] a plot has a method for drawing. *)
object (self)


  val plot_width = 1.0

  val plot_height = 1.0

  method width = plot_width

  method height = plot_height

  method private title = match title with
    | Some t -> t
    | None -> "<not title>"


  method display =
    (** [display] opens a lablgtk window showing the plot. *)
    Spt_gtk.create_display self self#title


  method virtual draw : context -> unit
    (** [draw ctx] displays the plot to the given drawing context. *)


  method output filename =
    (** [output] saves the plot to a filename.  The type is pulled from
	the name, so you must include an extension *)
    Spt_cairo.save self filename

end