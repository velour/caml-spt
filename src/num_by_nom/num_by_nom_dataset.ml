(** Numeric by nominal datasets.

    @author eaburns
    @since 2010-05-21
*)

open Drawing
open Geometry

let between_padding = Length.Pt 5.
  (** Padding between each dataset. *)

class virtual dataset name =
  (** [dataset name] is a dataset that is plottable on a nominal x
      axis and a numeric y axis. *)
object

  val name = (name : string)
    (** The name of the dataset is what appears on the x-axis. *)

  method virtual dimensions : range
    (** [dimensions] gets the min and maximum value from the
	dataset. *)


  method x_label_height : context -> text_style -> float -> float =
    (** [x_label_height context style width] is the height of the
	label on thesrc/ x-axis. *)
    (fun ctx style width -> fixed_width_text_height ctx ~style width name)


  method draw_x_label :
    context -> x:float -> y:float -> text_style -> width:float -> unit =
    (** [draw_x_label context ~x ~y style ~width] draws the x-axis
	label to the proper location. *)
    (fun ctx ~x ~y style ~width ->
       let half_width = width /. 2. in
       draw_fixed_width_text ctx ~x:(x +. half_width) ~y ~style ~width name)

  method virtual residual :
    context -> src:range -> dst:range -> width:float -> x:float -> range
    (** [residual ctx ~src ~dst width x] get a rectangle containing
	the maximum amount the dataset will draw off of the
	destination rectangle in each direction. *)

  method n_items = 1		 (* Most things just have one item. *)
    (** [n_items] gets the number of dataset items.  Each item is
	allocated a fixed width across the plot.  A dataset with more
	than one item is allocated a proportion of the space that is
	[n_items] times the size of the single item width. *)

  method virtual draw :
    context -> src:range -> dst:range -> width:float -> x:float ->unit
    (** [draw ctx ~src ~dst width x] draws the dataset to the
	plot.  [x] is the left-hand-side x value. *)
end

(** {6 Grouped datasets} ****************************************)

let group_padding = Length.Pt 10.
  (** Padding on either side of a group. *)

let overline_style =
  (** The line style of the line showing the group. *)
  {
    line_color = black;
    line_dashes = [| |];
    line_width = Length.Pt 1.;
  }

let overline_padding = Length.Pt 4.
  (** Padding between the overline and the x-axis text. *)

class dataset_group group_name datasets =
object(self)

  inherit dataset group_name

  method private dataset_width ctx width =
    let n = float (List.length datasets) in
    let between_padding_amt = (n -. 1.) *. (ctx.units between_padding) in
    let group_padding = (ctx.units group_padding) *. 2. in
      if n > 1.
      then (width -. between_padding_amt -. group_padding) /. n
      else width


  method private dataset_name_height ctx style width =
    (** [dataset_name_height ctx style width] gets the height of the
	dataset names on the x-axis. *)
    let ds_width = self#dataset_width ctx width in
      List.fold_left
	(fun h ds ->
	   let ht = ds#x_label_height ctx style ds_width in
	     if ht > h then ht else h)
	neg_infinity datasets

  method dimensions =
    List.fold_left (fun r ds -> range_extremes r ds#dimensions)
      (range ~min:infinity ~max:neg_infinity) datasets


  method x_label_height ctx style width =
    let text_height = font_suggested_line_height ~style ctx in
    let overline_height = ctx.units overline_style.line_width in
      overline_height /. 2. +. (ctx.units overline_padding)
      +. (self#dataset_name_height ctx style width)
      +. text_height			(* padding *)
      +. (fixed_width_text_height ctx ~style width group_name)


  method draw_x_label ctx ~x ~y style ~width =
    let between_padding = ctx.units between_padding in
    let ds_name_height = self#dataset_name_height ctx style width in
    let ds_width = self#dataset_width ctx width in
    let center = x +. (width /. 2.) in
    let text_height = font_suggested_line_height ~style ctx in
    let overline_height = ctx.units overline_style.line_width in
    let y' = y +. (overline_height /. 2. +. (ctx.units overline_padding)) in
    let group_padding = ctx.units group_padding in
    let x0 = x +. group_padding in
      draw_line ctx ~style:overline_style
	[point x0 y; point (x +. width -. group_padding) y];
      ignore
	(List.fold_left
	   (fun x ds ->
	      ds#draw_x_label ctx ~x ~y:y' style ~width:ds_width;
	      x +. ds_width +. between_padding)
	   x0 datasets);
      draw_fixed_width_text ctx ~x:center
	~y:(y +. ds_name_height +. text_height)
	~style ~width group_name


  method residual ctx ~src ~dst ~width ~x =
    let ds_width = self#dataset_width ctx width in
    let between_padding = ctx.units between_padding in
    let x0 = x +. (ctx.units group_padding) in
      fst (List.fold_left
	     (fun (r, x) ds ->
		(range_extremes r (ds#residual ctx ~src ~dst
				     ~width:ds_width ~x),
		 x +. ds_width +. between_padding))
	     ((range ~min:infinity ~max:neg_infinity), x0) datasets)


  method n_items = List.fold_left (fun s ds -> s + ds#n_items) 0 datasets
    (* Sums the number of items in the group. *)


  method draw ctx ~src ~dst ~width ~x =
    let ds_width = self#dataset_width ctx width in
    let between_padding = ctx.units between_padding in
    let x0 = x +. (ctx.units group_padding) in
      ignore (List.fold_left
		(fun x ds ->
		   ds#draw ctx ~src ~dst ~width:ds_width ~x;
		   x +. ds_width +. between_padding)
		x0 datasets)
end

let dataset_group name datasets = new dataset_group name datasets
