(** Box plots.

    @author eaburns
    @since 2010-05-21
*)

open Geometry
open Drawing

let minf a b = if (a:float) < b then a else b
let maxf a b = if (a:float) > b then a else b

let line_style = { default_line_style with line_width = Length.Pt 1. }

class boxplot_dataset ?(radius=Length.Pt 2.) name values =
  let outliers, data = Statistics.separate_outliers values in
  let mean, conf_interval = Statistics.mean_and_interval data in
object(self)

  inherit Num_by_nom_dataset.dataset name

  val conf_lower = mean -. conf_interval
  val conf_upper = mean +. conf_interval
  val mean = mean
  val q1 = Statistics.percentile 25. values
  val q2 = Statistics.percentile 50. values
  val q3 = Statistics.percentile 75. values
  val outliers = outliers
  val data = data

  method dimensions =
    let vs =
      Array.append
	[| mean; conf_lower; conf_upper; q1; q2; q3; |]
	values
    in
      range
	~min:(Array.fold_left minf infinity vs)
	~max:(Array.fold_left maxf neg_infinity vs)


  method residual _ ~src:_ ~dst:_ ~width:_ ~x:_ = range 0. 0.


  method draw ctx ~src ~dst ~width ~x =
    let tr = range_transform ~src ~dst in
    let center = x +. (width /. 2.) in
    let x0 = x and x1 = x +. width in
    let conf_min = center -. (width /. 16.) in
    let conf_max = center +. (width /. 16.) in
    let min, max =
      Array.fold_left (fun (min, max) v -> (minf min v), (maxf max v))
	(infinity, neg_infinity) data
    in
    let mean' = tr mean in
      draw_points ctx radius ~color:black Ring_glyph
	(Array.fold_left
	   (fun a v -> (point center (tr v)) :: a)
	   [] outliers);
      fill_rectangle ctx ~color:(color ~r:0.7 ~g:0.7 ~b:0.7 ~a:1.)
	(rectangle ~x_min:conf_min ~x_max:conf_max
	   ~y_min:(tr conf_lower) ~y_max:(tr conf_upper));
      draw_rectangle ctx ~style:line_style
	(rectangle ~x_min:x0 ~x_max:x1 ~y_min:(tr q1) ~y_max:(tr q3));
      draw_line ctx ~style:line_style [ point x0 mean'; point x1 mean'; ];
      Errbar.draw_up ctx ~style:line_style ~src ~dst
	~x:center ~y:q3 ~mag:(max -. q3);
      Errbar.draw_down ctx ~style:line_style ~src ~dst
	~x:center ~y:q1 ~mag:(q1 -. min);

end
