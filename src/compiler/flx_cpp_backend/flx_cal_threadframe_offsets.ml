
open Flx_util
open Flx_list
open Flx_types
open Flx_btype
open Flx_bexpr
open Flx_bbdcl
open Flx_mtypes2
open Flx_name
open Flx_unify
open Flx_typing
open List
open Flx_print
open Flx_exceptions
open Flx_maps
open Flx_gen_shape

let find_thread_vars_with_type bsym_table =
  let vars = ref [] in
  Flx_bsym_table.iter begin fun k parent bsym ->
    match parent, Flx_bsym.bbdcl bsym with
    | None,BBDCL_val (_,t,(`Val | `Var)) -> vars := (k,t) :: !vars
    | None,BBDCL_val (_,t,`Ref) -> vars := (k, btyp_pointer t) :: !vars
    | _ -> ()
  end bsym_table;
  !vars


let gen_thread_frame_offsets s syms bsym_table last_ptr_map =
  let vars = find_thread_vars_with_type bsym_table in
  let ts = [] in
  let name = "thread_frame_t" in
  let offsets =
    concat
    (
      map
      (fun (idx,typ)->
        let mem = cpp_instance_name syms bsym_table idx ts in
        let offsets = get_offsets syms bsym_table typ in
        map
        (fun offset ->
          "offsetof("^name^","^mem^")+" ^ offset
        )
        offsets
      )
      vars
    )
  in
  let n = length offsets in
  bcat s
  (
    "\n//OFFSETS for "^ name ^ "\n"
  );
  gen_offset_data s n name offsets false [] (Some "::flx::gc::generic::gc_flags_immobile") last_ptr_map

