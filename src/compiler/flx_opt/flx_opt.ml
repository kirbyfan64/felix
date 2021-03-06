(* Convenience function for printing debug statements. *)
let print_debug syms msg =
  if syms.Flx_mtypes2.compiler_options.Flx_options.print_flag
  then print_endline msg

let print_time syms msg f =
  let t0 = Unix.gettimeofday () in
  let result = f () in
  let elapsed = Unix.gettimeofday () -. t0 in
  if syms.Flx_mtypes2.compiler_options.Flx_options.showtime
  then print_endline (String.sub (msg ^ "                                        ") 0 40
        ^ string_of_int (int_of_float elapsed) ^ "s");
  result


(* Convert curried functions to uncurried functions so they can ba applied
 * directly instead of requiring closures. *)
let uncurry_functions syms bsym_table =
  let bsym_table = ref bsym_table in
  let counter = ref 0 in

  while Flx_uncurry.uncurry_gen syms !bsym_table > 0 do
    incr counter;
    if !counter > 10 then failwith "uncurry exceeded 10 passes";

    (* Remove unused symbols. *)
    bsym_table := Flx_use.copy_used syms !bsym_table
  done;

  !bsym_table

let mkproc syms bsym_table =
  (* Clean up the symbol table. *)
  let bsym_table = Flx_use.copy_used syms bsym_table in

  (* XXX: What does mkproc do? *)
  (* see below, it turns functions into procedures, by assigning
   * the return value to where an extra argument points
   *)
  let bsym_table = ref bsym_table in
  let counter = ref 0 in
  while Flx_mkproc.mkproc_gen syms !bsym_table > 0 do
    incr counter;
    if !counter > 10 then failwith "mkproc exceeded 10 passes";

    (* Clean up the symbol table. *)
    bsym_table := Flx_use.copy_used syms !bsym_table;
  done;

  !bsym_table


(* Convert functions into stack calls. *)
let stack_calls syms bsym_table =
  print_debug syms "//Calculating stackable calls";

  let label_map = Flx_label.create_label_map
    bsym_table
    syms.Flx_mtypes2.counter
  in
  let label_usage = Flx_label.create_label_usage bsym_table label_map in
  Flx_stack_calls.make_stack_calls
    syms
    bsym_table
    label_map
    label_usage;

  print_debug syms "//stackable calls done";

  bsym_table


(* Do some platform independent optimizations of the code. *)
let optimize_bsym_table' syms bsym_table root_proc =
  print_debug syms "//OPTIMISING";

  print_time syms "[flx_opt]; Finding roots" begin fun () ->
  (* Find the root and exported functions and types. *)
  Flx_use.find_roots syms bsym_table root_proc syms.Flx_mtypes2.bifaces end;

  let bsym_table = 
   print_time syms "[flx_opt]; Monomorphising" begin fun () ->
  (* monomorphise *)
  Flx_numono.monomorphise2 true syms bsym_table end
  in

  print_time syms "[flx_opt]; Verifying typeclass elimination" begin fun () ->
  (* check no typeclasses are left *)
  Flx_bsym_table.iter
  (fun id pa sym -> 
     match sym.Flx_bsym.bbdcl with 
     | Flx_bbdcl.BBDCL_axiom
     | Flx_bbdcl.BBDCL_lemma
     | Flx_bbdcl.BBDCL_reduce
     | Flx_bbdcl.BBDCL_invalid  
     | Flx_bbdcl.BBDCL_module 
     | Flx_bbdcl.BBDCL_instance _ 
     | Flx_bbdcl.BBDCL_typeclass _ 
       -> assert false 
     | _ -> () 
  )
  bsym_table
  end;


  let bsym_table = 
  print_time syms "[flx_opt]; Downgrading abstract types to representations" begin fun () ->
  (* Downgrade abstract types now. *)
  Flx_strabs.strabs bsym_table end 
  in

  print_time syms "[flx_opt]; Verifying abstract type elimination" begin fun () -> 
  (* check no abstract types are left *)
  Flx_bsym_table.iter
  (fun id pa sym -> 
     match sym.Flx_bsym.bbdcl with 
     | Flx_bbdcl.BBDCL_newtype _ -> assert false 
     | _ -> () 
  )
  bsym_table
  end ;

  let bsym_table = print_time syms "[flx_opt]; Removing unused symbols" begin fun () ->
  (* Clean up the symbol table. *)
  Flx_use.copy_used syms bsym_table end
  in

  let bsym_table = print_time syms "[flx_opt]; Uncurrying curried function" begin fun () -> 
  (* Uncurry curried functions. *)
  uncurry_functions syms bsym_table end
  in

  let bsym_table = print_time syms "[flx_opt]; Converting functions to procedures" begin fun () ->
  (* convert functions to procedures *)
  mkproc syms bsym_table end
  in

  let bsym_table = print_time syms "[flx_opt]; Generating wrappers (new)" begin fun () ->
  (* make wrappers for non-function functional values *)
  Flx_mkcls2.make_wrappers syms bsym_table end
  in

  print_time syms "[flx_opt]; Inlining" begin fun () -> 
  (* Perform the inlining. *)
  Flx_inline.heavy_inlining syms bsym_table end;

  let bsym_table = print_time syms "[flx_opt]; Remove unused symbols" begin fun () -> 
  (* Clean up the symbol table. *)
  Flx_use.copy_used syms bsym_table end
  in

  print_time syms "[flx_opt]; Eliminate dead code" begin fun () ->
  (* Eliminate dead code. *)
  let elim_state = Flx_elim.make_elim_state syms bsym_table in
  Flx_elim.eliminate_unused elim_state end;

  let bsym_table = print_time syms "[flx_opt]; Do stack call optimisation" begin fun () ->
  (* Convert functions into stack calls. *)
  stack_calls syms bsym_table end
  in

  bsym_table


let optimize_bsym_table syms bsym_table root_proc =
  print_time syms "[flx_opt]; optimisation pass complete" begin fun () -> 
  optimize_bsym_table' syms bsym_table root_proc end

