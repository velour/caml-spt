(** The plot hierarchy.

    @author eaburns
    @since 2010-04-23
*)

open Geometry
open Drawing

(** {1 Plots} ****************************************)

class virtual plot =
  (** [plot] a plot has a method for drawing. *)
object
  method virtual draw : context -> unit
    (** [draw ctx] displays the plot to the given drawing
	context. *)
end


and num_by_num_plot
  ?label_style ?tick_style ~title ~xlabel ~ylabel ?scale datasets =
  (** [num_by_num_plot ?label_style ?tick_style ~title ~xlabel ~ylabel
      ?scale datasets] a plot that has a numeric x and y axis. *)
  let tick_style = match tick_style with
    | None ->
	{
	  text_font = "Palatino-Roman";
	  text_size = 0.03;
	  text_slant = Cairo.FONT_SLANT_NORMAL;
	  text_weight = Cairo.FONT_WEIGHT_NORMAL;
	  text_color = black;
	}
    | Some s -> s
  and label_style = match label_style with
    | None ->
	{
	  text_font = "Palatino-Roman";
	  text_size = 0.04;
	  text_slant = Cairo.FONT_SLANT_NORMAL;
	  text_weight = Cairo.FONT_WEIGHT_NORMAL;
	  text_color = black;
	}
    | Some s -> s in
object (self)
  inherit plot

  val text_padding = 0.01
    (** Padding around text *)

  val datasets = (datasets : num_by_num_dataset list)
    (** The list of datasets. *)

  method private scale =
    (** [scale] computes the scale of the x and y axes. *)
    match scale with
      | None -> failwith "Automatic dimensions is currently unimplemented"
      | Some rect -> rect


  method private xticks =
    (** [xticks] computes the location of the x-axis tick marks. *)
    let s = self#scale in
      Numeric_axis.tick_locations s.x_min s.x_max


  method private yticks =
    (** [yticks] computes the location of the y-axis tick marks. *)
    let s = self#scale in
      Numeric_axis.tick_locations s.y_min s.y_max


  method private dest_rect ctx =
    (** [dest_rect ctx] get the dimensions of the destination
	rectangle. *)
    let title_height =
      match title with
	| None -> 0.
	| Some txt -> snd (text_dimensions ctx ~style:label_style txt) in
    let dst =
      Numeric_axis.resize_for_x_axis
	ctx ~label_style ~tick_style ~pad:text_padding ~src:self#scale
	~dst:(rectangle ~x_min:0. ~x_max:1. ~y_min:1.
		~y_max:(title_height +. text_padding))
	xlabel self#xticks
    in
    let x_min' =
      Numeric_axis.resize_for_y_axis ctx ~label_style ~tick_style
	~pad:text_padding ~min:dst.x_min ylabel self#yticks
    in
      { dst with x_min = x_min'; }


  method draw ctx =
    (** [draw ctx] draws the numeric by numeric plot to the given
	context. *)
    let src = self#scale in
    let dst = self#dest_rect ctx in
      begin match title with
	| None -> ()
	| Some txt ->
	    draw_text_centered_below ~style:label_style ctx 0.5 0. txt
      end;
      Numeric_axis.draw_x_axis ctx ~tick_style ~label_style ~pad:text_padding
	~y:1.
	~x_min:src.x_min ~x_max:src.x_max
	~x_min':dst.x_min ~x_max':dst.x_max
	xlabel self#xticks;
      Numeric_axis.draw_y_axis ctx ~tick_style ~label_style ~pad:text_padding
	~x:0.
	~y_min:src.y_min ~y_max:src.y_max
	~y_min':dst.y_min ~y_max':dst.y_max
	ylabel self#yticks

end


and num_by_nom_plot ~title ~ylabel datasets =
  (** [num_by_nom_plot ~title ~ylabel datasets] a plot that has a nominal x
      axis and a numeric y axis. *)
object
  inherit plot

  val datasets = (datasets : num_by_nom_dataset list)

  method draw _ = failwith "Unimplemented"
end


(** {1 Datasets} ****************************************)

and virtual num_by_num_dataset name =
  (** [num_by_num_dataset name] is a dataset that is plottable on a
      numeric x and y axis. *)
object
  val name = (name : string option)
    (** The name of the dataset.  If there is no name then the dataset
	doesn't appear in the legend. *)

  method virtual dimensions : rectangle
    (** [dimensions] is the dimensions of this dataset in
	data-coordinates. *)

  method virtual draw :
    context -> src:rectangle -> dst:rectangle -> int -> unit
    (** [draw ctx ~src ~dst rank] draws the data to the plot given
	[src], the data coordinate system and [dst] the destination
	coordinate system and [rank] the number of datasets that were
	plotted before this one. *)

  method virtual draw_legend_entry :
    context -> x:float -> y:float -> float
    (** [draw_legend_entry ctx ~x ~y] draws the legend entry to the
	given location ([x] is the left-edge and [y] is top edge of the
	destination) and the result is the y-coordinate of the bottom edge
	of the entry that was just drawn. *)
end

and virtual num_by_nom_dataset name =
  (** [num_by_nom_dataset name] is a dataset that is plottable on a
      nominal x axis and a numeric y axis. *)
object

  val name = (name : string)
    (** The name of the dataset is what appears on the x-axis. *)

  method virtual x_label_height : float -> float
    (** [x_label_height width] is the height of the label on the
	x-axis. *)

  method virtual draw_x_label :
    context -> x:float -> y:float -> width:float -> unit
    (** [draw_x_label context ~x ~y ~width] draws the x-axis label to
	the proper location. *)

  method virtual draw :
    context -> src:float -> dst:float -> width:float -> int -> unit
    (** [draw ctx src dst width rank] draws the dataset to the plot. *)

end
