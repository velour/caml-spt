(** A bunch of calls to cairo - Currently just for saving files *)


type files =
  | Postscript
  | PNG
  | PDF
  | Unknown of string

<<<<<<< /home/aifs1/jtd7/research/spt/src/spt_cairo.ml
let background_resize context width height =
=======

(* resizing functionality and units conversion *)

let points_to_cm pval =
  (** converts a number of points into corresponding centimeters measure *)
  (float_of_int pval) /. points_per_centimeter


let points_to_in pval =
  (** converts a number of points into corresponding inches measure *)
  (float_of_int pval) /. (points_per_centimeter /. 2.54)


let pixels_to_cm pval =
  (** converts a number of points into corresponding centimeters measure *)
  (float_of_int pval) /. pixels_per_centimeter


let pixels_to_in pval =
  (** converts a number of points into corresponding inches measure *)
  (float_of_int pval) /. (pixels_per_centimeter /. 2.54)


let cm_to_points cms =
  cms *. points_per_centimeter


let in_to_points inches =
  cm_to_points (inches *. 2.54)


let cm_to_pixels cms =
  cms *. pixels_per_centimeter


let in_to_pixels inches =
  cm_to_points (inches *. 2.54)


let resize context plot width height =
>>>>>>> /tmp/spt_cairo.ml~other.SDtBjp
  (* Scale so that drawing can take place between 0. and 1. *)
  plot#set_size ~w:width ~h:height;
  let x_ratio, y_ratio = plot#aspect_ratio in
    Drawing.fill_rectangle context ~color:Drawing.white
      (Geometry.rectangle 0. width 0. height);
    Drawing.scale context (width /. x_ratio) (height /. y_ratio)


(* saving functionality *)
let as_png width height plot filename =
  (** [width] in centimeters, float
      [height] in centimeters, float *)
<<<<<<< /home/aifs1/jtd7/research/spt/src/spt_cairo.ml
  let width = Sizing.cm_to_pixels width
  and height = Sizing.cm_to_pixels height in
=======
  let width_px = cm_to_pixels width
  and height_px = cm_to_pixels height in
>>>>>>> /tmp/spt_cairo.ml~other.SDtBjp
  let surface = (Cairo.image_surface_create
		   Cairo.FORMAT_ARGB32 ~width:(int_of_float width_px)
		   ~height:(int_of_float height_px)) in
  let context = Cairo.create surface in
    resize context plot width_px height_px;
    plot#draw context;
    Cairo_png.surface_write_to_file surface filename


let as_ps width height plot filename =
<<<<<<< /home/aifs1/jtd7/research/spt/src/spt_cairo.ml
  let width = Sizing.cm_to_points width
  and height = Sizing.cm_to_points height in
=======
  let width_pt = cm_to_points width
  and height_pt = cm_to_points height in
>>>>>>> /tmp/spt_cairo.ml~other.SDtBjp
  let chan = open_out filename in
  let surface = (Cairo_ps.surface_create_for_channel chan
		   ~width_in_points:width_pt
		   ~height_in_points:height_pt) in
  let context = Cairo.create surface in
    resize context plot width_pt height_pt;
    plot#draw context;
    Cairo.surface_finish surface;
    close_out chan


let as_pdf width height plot filename =
<<<<<<< /home/aifs1/jtd7/research/spt/src/spt_cairo.ml
  let width = Sizing.cm_to_points width
  and height = Sizing.cm_to_points height in
=======
  let width_pt = cm_to_points width
  and height_pt = cm_to_points height in
>>>>>>> /tmp/spt_cairo.ml~other.SDtBjp
  let chan = open_out filename in
  let surface = (Cairo_pdf.surface_create_for_channel chan
		   ~width_in_points:width_pt
		   ~height_in_points:height_pt) in
  let context = Cairo.create surface in
    resize context plot width_pt height_pt;
    plot#draw context;
    Cairo.surface_finish surface;
    close_out chan



(* determining filetype and saving *)

let filetype file =
  let file_split = Str.split (Str.regexp "\\.") file in
    match (List.rev file_split) with
	[] -> Unknown ""
      | ext::tl -> (match (String.lowercase ext) with
		      | "ps" -> Postscript
		      | "png" -> PNG
		      | "pdf" -> PDF
		      | _ -> Unknown ext)


let save width height plot filename =
  match (filetype filename) with
    | Postscript -> as_ps width height plot filename
    | PNG -> as_png width height plot filename
    | PDF -> as_pdf width height plot filename
    | Unknown ext -> failwith ("Cannot save unknown filetype " ^ ext)



(* EOF *)
