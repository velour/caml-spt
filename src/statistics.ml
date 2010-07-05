(** Some statistic functions.

    @author eaburns
    @since 2010-04-28
*)

type float_ref = { mutable v : float }

let float_ref x = { v = x }

let (<--) r v = r.v <- v

let (!!) r = r.v

let mean vls =
  (** [mean vls] gets the mean of an array of floats. *)
  let n = float (Array.length vls) in
  let sum = float_ref 0. in
    Array.iter (fun v -> sum <-- !!sum +. v) vls;
    !!sum /. n


let mean_and_stdev vls =
  (** [mean_and_stdev vls] gets the mean and standard deviation of an
      array of floats. *)
  let n = float (Array.length vls) in
  let sum = float_ref 0. in
    Array.iter (fun v -> sum <-- !!sum +. v) vls;
    let mean = !!sum /. n in
    let diffs = float_ref 0. in
      Array.iter (fun v -> diffs <-- !!diffs +. (v -. mean) ** 2.) vls;
      mean, sqrt (!!diffs /. n)


let mean_and_interval vls =
  (** [mean_and_interval vls] gives the mean and the magnitude of the
      95% confidence interval on the mean. *)
  let mu, sigma = mean_and_stdev vls in
  let n = float (Array.length vls) in
    mu, 1.96 *. sigma /. (sqrt n)


let percentile p vls =
  (** [percentile p vls] computes the [p] percentile of the values
      [vls] by ranking them.

      According to wikipedia, this procedure is recommended by the
      National Institute of Standards and Technology (NIST). *)
  if p < 0. || p > 100. then invalid_arg "percentile: out of bounds";
  let cmp (a : float) b = if a < b then ~-1 else if a > b then 1 else 0 in
  let ranked = Array.copy vls in
  let num = float (Array.length ranked) in
  let n = p *. (num -. 1.) /. 100. +. 1. in
  let k = truncate n in
  let d = n -. (float k) in
    Array.sort cmp ranked;
    match n with
      | n when n <= 1. -> ranked.(0)
      | n when n >= num -> ranked.((truncate num) - 1)
      | n -> ranked.(k - 1) +. d *. (ranked.(k) -. ranked.(k - 1))


(** {1 Density estimation} ****************************************)

let gaussian_kernel =
  (** [gaussian_kernel] makes a gaussian kernel function. *)
  let coeff = 1. /. (sqrt (2. *. Geometry.pi)) in
    (fun u -> coeff *. (exp (~-.(u ** 2.) /. 2.)))


let make_kernel_density_estimator kernel bandwidth data =
  (** [make_kernel_density_estimator kernel bandwidth data] makes a
      density estimation function. *)
  let n = Array.length data in
  let nf = float n in
    (fun x ->
       let sum = float_ref 0. in
	 for i = 0 to n - 1 do
	   let diff = x -. data.(i) in
	     sum <-- !!sum +. (kernel (diff /. bandwidth)) /. bandwidth;
	 done;
	 !!sum /. nf)


(* EOF *)
