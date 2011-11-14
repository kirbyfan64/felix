open Flx_ast
open Flx_types
open Flx_mtypes2

val build_type_constraints:
  Flx_types.bid_t ref ->
  Flx_bsym_table.t ->
  (typecode_t -> Flx_btype.t) -> (* bind type *)
  Flx_srcref.t ->
  (string * bid_t * typecode_t) list -> (* local vs list *)
  Flx_btype.t
