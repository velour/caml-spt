(** Some basic Cairo drawing primitives.

    @author eaburns
    @since 2010-04-19
*)


open Geometry


(** {1 Color} ****************************************)

type color = { r : float; g : float; b : float; a : float}

let black = { r = 0.; g = 0.; b = 0.; a = 1.; }
  (** The color black. *)

let white = { r = 1.; g = 1.; b = 1.; a = 1.; }
  (** The color white. *)

let red = { r = 1.; g = 0.; b = 0.; a = 1.; }
  (** The color red. *)

let green = { r = 0.; g = 1.; b = 0.; a = 1.; }
  (** The color green. *)

let blue = { r = 0.; g = 0.; b = 1.; a = 1.; }
  (** The color blue. *)

let set_color ctx color =
  (** [set_color ctx color] sets the current color. *)
  Cairo.set_source_rgba ctx color.r color.g color.b color.a


(** {1 Text} ****************************************)

type text_style = {
  font : string;
  size : float;
  slant : Cairo.font_slant;
  weight : Cairo.font_weight;
  color : color;
}

let default_text_style =
  (** The default style for text. *)
  {
    font = "Palatino-Roman";
    size = 0.03;
    slant = Cairo.FONT_SLANT_NORMAL;
    weight = Cairo.FONT_WEIGHT_NORMAL;
    color = black;
  }


let set_text_style ctx style =
  (** [set_text_stlye ctx style] sets the text style. *)
  set_color ctx style.color;
  Cairo.select_font_face ctx style.font style.slant style.weight;
  Cairo.set_font_size ctx style.size


let set_text_style_option ctx = function
    (** [set_text_style_option ctx style] sets the style if there was
	one specified. *)
  | None -> ()
  | Some style -> set_text_style ctx style


let draw_string ctx ?style ?(angle=0.) x y str =
  (** [draw_string ctx ?style ?angle x y str] displays the text at
      the given center point. *)
  set_text_style_option ctx style;
  let te = Cairo.text_extents ctx str in
  let w = te.Cairo.text_width and h = te.Cairo.text_height in
  let x_offs = te.Cairo.x_bearing and y_offs = te.Cairo.y_bearing in
    Cairo.save ctx;
    Cairo.move_to ctx 0. 0.;
    Cairo.translate ctx x y;
    Cairo.rotate ctx (angle *. (Math.pi /. 180.));
    Cairo.move_to ctx ~-.((w /. 2.) +. x_offs) ~-.((h /. 2.) +. y_offs);
    Cairo.show_text ctx str;
    Cairo.restore ctx


let string_dimensions ctx ?style str =
  (** [string_dimensions ctx ?style str] gets the dimensions of the
      text.  *)
  set_text_style_option ctx style;
  let te = Cairo.text_extents ctx str in
    te.Cairo.text_width, te.Cairo.text_height


(** {2 Formatted text} ****************************************)

let drawf ctx ?style ?(angle=0.) x y fmt =
  (** [drawf ctx ?style ?angle x y fmt] displays the formatted text at
      the given center point. *)
  Printf.kprintf (draw_string ctx ?style ~angle x y) fmt


let dimensionsf ctx ?style fmt =
  (** [dimensionsf ctx ?style fmt] gets the dimensions of the
      formatted text and returns the string.  *)
  let str_and_dims str =
    let w, h = string_dimensions ctx ?style str in
      str, w, h
  in Printf.kprintf str_and_dims fmt


(** {2 Fixed width text} ****************************************)


let default_line_space = 0.005
  (** The default spacing between lines of text. *)


let hypenate_word ctx width word =
  (** [hypenate_word ctx width word] hyphenates a word that is
      too long to fit across the given width. *)
  let partition word i =
    let fst = String.sub word 0 (i + 1) in
    let snd = String.sub word i ((String.length word) - i) in
      fst, snd
  in
  let n = String.length word in
  let rec do_hyphenate i =
    if i < n
    then begin
      let proposed, _ = partition word i in
      let w, h = string_dimensions ctx (proposed ^ "-") in
	if w > width
	then begin
	  let fst, snd = partition word (i - 1) in
	    fst ^ "-", snd
	end else do_hyphenate (i + 1)
    end else word, ""
  in do_hyphenate 1


let fixed_width_lines ctx width string =
  (** [fixed_width_lines ctx width string] gets a list of lines that
      that will display within the given width.  Assumes the given
      style has already been set. *)
  let rec get_line accum cur_line = function
    | [] -> List.rev (cur_line :: accum)
    | hd :: tl when cur_line = "" ->
	let w, _ = string_dimensions ctx hd in
	  if w > width
	  then begin
	    let first, last = hypenate_word ctx width hd in
	      get_line (first :: accum) "" (last :: tl)
	  end else get_line accum hd tl
    | (hd :: tl) as words ->
	let proposed_line = cur_line ^ " " ^ hd in
	let w, h = string_dimensions ctx proposed_line in
	  if w > width
	  then get_line (cur_line :: accum) "" words
	  else get_line accum proposed_line tl
  in
  let words = Str.split (Str.regexp " +\\|\t+\\|\n+\\|\r+") string in
    get_line [] "" words


let fixed_width_text_height ctx
    ?(line_space=default_line_space) ?style width string =
  (** [fixed_width_text_height ctx ?line_space ?style width string] gets
      the height of the fixed width text.  *)
  set_text_style_option ctx style;
  let lines = fixed_width_lines ctx width string in
    List.fold_left (fun sum line ->
		      let _, h = string_dimensions ctx line in
			h +. line_space +. sum)
      (~-.line_space) lines


let draw_fixed_width_text ctx
    ?(line_space=default_line_space) ?style ~x ~y ~width string =
  (** [draw_fixed_width_text ctx ?line_space ?style ~x ~y ~width
      string] displays the given fixed-width text where [x], [y] is
      the location of the top center. *)
  set_text_style_option ctx style;
  let lines = fixed_width_lines ctx width string in
    ignore (List.fold_left (fun y line ->
			      let w, h = string_dimensions ctx line in
				draw_string ctx x (y +. h /. 2.) line;
				y +. h +. line_space)
	      y lines)

(** {1 Lines} ****************************************)


type line_style = {
  line_color : color;
  line_dashes : float array;
  line_width : float;
}

let default_line_style =
  (** The default line style. *)
  {
    line_color = black;
    line_width = 0.002;
    line_dashes = [||];
  }


let set_line_style ctx style =
  (** [set_line_style ctx style] sets the line style. *)
  set_color ctx style.line_color;
  Cairo.set_dash ctx style.line_dashes 0.;
  Cairo.set_line_width ctx style.line_width


let set_line_style_option ctx = function
    (** [set_line_style_option ctx style] sets the line style if there
	is one *)
  | None -> ()
  | Some style -> set_line_style ctx style


let draw_line ctx ?box ?style points =
  (** [draw_line ctx ?box ?style points] draws the given line
      optionally within the given bounding box. *)
  set_line_style_option ctx style;
  match box with
    | None ->
	begin match points with
	  | [] -> ()
	  | p :: tl ->
	      Cairo.move_to ctx p.x p.y;
	      List.iter (fun p -> Cairo.line_to ctx p.x p.y) tl;
	      Cairo.stroke ctx
	end
    | Some box ->
	let rec draw_points = function
	  | _ :: []
	  | [] -> ()
	  | p0 :: ((p1 :: _) as tl) ->
	      let p0', p1' = clip_line_segment box ~p0 ~p1 in
		Cairo.move_to ctx p0'.x p0'.y;
		Cairo.line_to ctx p1'.x p1'.y;
		draw_points tl
	in
	  draw_points points;
	  Cairo.stroke ctx


let draw_rectangle ctx ?style r =
  (** [draw_rectangle ctx ?style r] draws the given rectangle. *)
  set_line_style_option ctx style;
  Cairo.rectangle ctx
    r.x_min r.y_min (r.x_max -. r.x_min) (r.y_max -. r.y_min);
  Cairo.stroke ctx
