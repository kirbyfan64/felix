open Format
open Flx_ast
open Flx_types
open Flx_format

type btype_qual_t = [
  | Flx_ast.base_type_qual_t
  | `Bound_needs_shape of Flx_btype.t
]

type breqs_t = (Flx_types.bid_t * Flx_btype.t list) list

(** Bound declarations. *)
type t =
  | BBDCL_module
  | BBDCL_function of   property_t list * bvs_t * Flx_bparams.t * Flx_btype.t * Flx_bexe.t list
  | BBDCL_procedure of  property_t list * bvs_t * Flx_bparams.t * Flx_bexe.t list
  | BBDCL_val of        bvs_t * Flx_btype.t
  | BBDCL_var of        bvs_t * Flx_btype.t
  | BBDCL_ref of        bvs_t * Flx_btype.t
  | BBDCL_tmp of        bvs_t * Flx_btype.t

  (* binding structures [prolog] *)
  | BBDCL_newtype of    bvs_t * Flx_btype.t
  | BBDCL_abs of        bvs_t * btype_qual_t list * code_spec_t * breqs_t
  | BBDCL_const of      property_t list * bvs_t * Flx_btype.t * code_spec_t * breqs_t
  | BBDCL_fun of        property_t list * bvs_t * Flx_btype.t list * Flx_btype.t * code_spec_t  * breqs_t * prec_t
  | BBDCL_callback of   property_t list * bvs_t * Flx_btype.t list * Flx_btype.t list * int * Flx_btype.t * breqs_t * prec_t
  | BBDCL_proc of       property_t list * bvs_t * Flx_btype.t list * code_spec_t  * breqs_t
  | BBDCL_insert of     bvs_t * code_spec_t * ikind_t * breqs_t

  | BBDCL_union of      bvs_t * (id_t * int * Flx_btype.t) list
  | BBDCL_struct of     bvs_t * (id_t * Flx_btype.t) list
  | BBDCL_cstruct of    bvs_t * (id_t * Flx_btype.t) list
  | BBDCL_typeclass of  property_t list * bvs_t
  | BBDCL_instance of   property_t list *
                        bvs_t *
                        Flx_btype.t (* constraint *) *
                        bid_t *
                        Flx_btype.t list
  | BBDCL_nonconst_ctor of bvs_t * bid_t * Flx_btype.t * int * Flx_btype.t *
                        bvs_t * Flx_btype.t (* existentials and constraint for GADTs *)
  | BBDCL_axiom
  | BBDCL_lemma
  | BBDCL_reduce

(* -------------------------------------------------------------------------- *)

let bbdcl_module () =
  BBDCL_module

let bbdcl_function (prop, bvs, ps, res, es) =
  BBDCL_function (prop, bvs, ps, res, es)

let bbdcl_procedure (prop, bvs, ps, es) =
  BBDCL_procedure (prop, bvs, ps, es)

let bbdcl_val (bvs, t) =
  BBDCL_val (bvs, t)

let bbdcl_var (bvs, t) =
  BBDCL_var (bvs, t)

let bbdcl_ref (bvs, t) =
  BBDCL_ref (bvs, t)

let bbdcl_tmp (bvs, t) =
  BBDCL_tmp (bvs, t)

let bbdcl_newtype (bvs, t) =
  BBDCL_newtype (bvs, t)

let bbdcl_abs (bvs, quals, code, breqs) =
  BBDCL_abs (bvs, quals, code, breqs)

let bbdcl_const (prop, bvs, t, code, breqs) =
  BBDCL_const (prop, bvs, t, code, breqs)

let bbdcl_fun (prop, bvs, ps, rt, code, breqs, prec) =
  BBDCL_fun (prop, bvs, ps, rt, code, breqs, prec)

let bbdcl_callback (prop, bvs, ps_cf, ps_c, k, rt, breqs, prec) =
  BBDCL_callback (prop, bvs, ps_cf, ps_c, k, rt, breqs, prec)

let bbdcl_proc (prop, bvs, ts, code, breqs) =
  BBDCL_proc (prop, bvs, ts, code, breqs)

let bbdcl_insert (bvs, code, ikind, breqs) =
  BBDCL_insert (bvs, code, ikind, breqs)

let bbdcl_union (bvs, cs) =
  BBDCL_union (bvs, cs)

let bbdcl_struct (bvs, cs) =
  BBDCL_struct (bvs, cs)

let bbdcl_cstruct (bvs, cs) =
  BBDCL_cstruct (bvs, cs)

let bbdcl_typeclass (prop, bvs) =
  BBDCL_typeclass (prop, bvs)

let bbdcl_instance (prop, bvs, cons, bid, ts) =
  BBDCL_instance (prop, bvs, cons, bid, ts)

let bbdcl_nonconst_ctor (bvs, uidx, ut, ctor_idx, ctor_argt, evs, etraint) =
  BBDCL_nonconst_ctor (bvs, uidx, ut, ctor_idx, ctor_argt, evs, etraint)

let bbdcl_axiom () =
  BBDCL_axiom

let bbdcl_reduce () =
  BBDCL_reduce

let bbdcl_lemma () =
  BBDCL_lemma

(* -------------------------------------------------------------------------- *)

(** Extract the parameters of a bound declaration. *)
let get_bparams = function
  | BBDCL_function (_,_,ps,_,_)
  | BBDCL_procedure (_,_,ps,_) -> ps
  | _ -> assert false

(** Extract the types of a bound declaration. *)
let get_ts = function
  | BBDCL_instance (_, _, _, _, ts) -> ts
  | _ -> []

(** Extract the bound type variables of a bound declaration. *)
let get_bvs = function
  | BBDCL_module -> []
  | BBDCL_function (_, bvs, _, _, _) -> bvs
  | BBDCL_procedure (_, bvs, _, _) -> bvs
  | BBDCL_val (bvs, _) -> bvs
  | BBDCL_var (bvs, _) -> bvs
  | BBDCL_ref (bvs, _) -> bvs
  | BBDCL_tmp (bvs, _) -> bvs
  | BBDCL_newtype (bvs, _) -> bvs
  | BBDCL_abs (bvs, _, _, _) -> bvs
  | BBDCL_const (_, bvs, _, _, _) -> bvs
  | BBDCL_fun (_, bvs, _, _, _, _, _) -> bvs
  | BBDCL_callback (_, bvs, _, _, _, _, _, _) -> bvs
  | BBDCL_proc (_, bvs, _, _, _) -> bvs
  | BBDCL_insert (bvs, _, _, _) -> bvs
  | BBDCL_union (bvs, _) -> bvs
  | BBDCL_struct (bvs, _) -> bvs
  | BBDCL_cstruct (bvs, _) -> bvs
  | BBDCL_typeclass (_, bvs) -> bvs
  | BBDCL_instance (_, bvs, _, _, _) -> bvs
  | BBDCL_nonconst_ctor (bvs, _, _, _, _, _, _) -> bvs
  | BBDCL_axiom -> []
  | BBDCL_lemma -> []
  | BBDCL_reduce -> []

(* -------------------------------------------------------------------------- *)

let iter
  ?(f_bid=fun _ -> ())
  ?(f_btype=fun _ -> ())
  ?(f_bexpr=fun _ -> ())
  ?(f_bexe=fun _ -> ())
  bbdcl
=
  let f_btype = Flx_btype.iter ~f_bid ~f_btype in
  let f_bexpr = Flx_bexpr.iter ~f_bid ~f_btype ~f_bexpr in
  let f_bexe = Flx_bexe.iter ~f_bid ~f_btype ~f_bexpr in
  let f_bvs = List.iter (fun (s,i) -> f_bid i) in
  let f_ps (ps,e) =
    List.iter begin fun p ->
      f_bid p.Flx_bparameter.pindex;
      f_btype p.Flx_bparameter.ptyp
    end ps;
    match e with Some e -> f_bexpr e | None -> ();
  in
  let f_breqs =
    List.iter begin fun (bid,ts) ->
      f_bid bid;
      List.iter f_btype ts
    end
  in
  let f_btype_qual = function
    | #base_type_qual_t -> ()
    | `Bound_needs_shape t -> f_btype t
  in
  match bbdcl with
  | BBDCL_module -> ()
  | BBDCL_function (props,bvs,ps,res,es) ->
      f_bvs bvs;
      f_ps ps;
      f_btype res;
      List.iter f_bexe es
  | BBDCL_procedure (props,bvs,ps,es) ->
      f_bvs bvs;
      f_ps ps;
      List.iter f_bexe es
  | BBDCL_val (bvs,t)
  | BBDCL_var (bvs,t)
  | BBDCL_ref (bvs,t)
  | BBDCL_tmp (bvs,t)
  | BBDCL_newtype (bvs,t) ->
      f_bvs bvs;
      f_btype t
  | BBDCL_abs (bvs,quals,code,breqs) ->
      f_bvs bvs;
      List.iter f_btype_qual quals;
      f_breqs breqs
  | BBDCL_const (props,bvs,t,code,breqs) ->
      f_bvs bvs;
      f_btype t;
      f_breqs breqs
  | BBDCL_fun (props,bvs,ps,rt,code,breqs,prec) ->
      f_bvs bvs;
      List.iter f_btype ps;
      f_btype rt;
      f_breqs breqs
  | BBDCL_callback (props,bvs,ps_cf,ps_c,k,rt,breqs,prec) ->
      f_bvs bvs;
      List.iter f_btype ps_cf;
      List.iter f_btype ps_c;
      f_btype rt;
      f_breqs breqs
  | BBDCL_proc (props,bvs,ps,code,breqs) ->
      f_bvs bvs;
      List.iter f_btype ps;
      f_breqs breqs
  | BBDCL_insert (bvs,code,ikind,breqs) ->
      f_bvs bvs;
      f_breqs breqs
  | BBDCL_union (bvs,cs) ->
      f_bvs bvs;
      List.iter (fun (n,i,t) -> f_btype t) cs
  | BBDCL_struct (bvs,cs)
  | BBDCL_cstruct (bvs,cs) ->
      f_bvs bvs;
      List.iter (fun (n,t) -> f_btype t) cs
  | BBDCL_typeclass (props,bvs) ->
      f_bvs bvs
  | BBDCL_instance (props,bvs,cons,bid,ts) ->
      f_bvs bvs;
      f_btype cons;
      f_bid bid;
      List.iter f_btype ts
  | BBDCL_nonconst_ctor (bvs,uidx,ut,ctor_idx,ctor_argt,evs,etraint) ->
      f_bvs bvs;
      f_bid uidx;
      f_btype ut;
      f_bid ctor_idx;
      f_btype ctor_argt;
      f_bvs evs;
      f_btype etraint
  | BBDCL_axiom -> ()
  | BBDCL_lemma -> ()
  | BBDCL_reduce -> ()

let map
  ?(f_bid=fun i -> i)
  ?(f_btype=fun t -> t)
  ?(f_bexpr=fun e -> e)
  ?(f_bexe=fun e -> e)
  bbdcl
=
  let f_btype = Flx_btype.map ~f_bid ~f_btype in
  let f_bexpr = Flx_bexpr.map ~f_bid ~f_btype ~f_bexpr in
  let f_bexe bexe = Flx_bexe.map ~f_bid ~f_btype ~f_bexpr bexe in
  let f_bvs = List.map (fun (s,i) -> s,f_bid i) in
  let f_ps (ps,e) =
    List.map begin fun p ->
      { p with
        Flx_bparameter.pindex=f_bid p.Flx_bparameter.pindex;
        ptyp=f_btype p.Flx_bparameter.ptyp }
    end ps,
    match e with Some e -> Some (f_bexpr e) | None -> None
  in
  let f_breqs =
    List.map begin fun (bid,ts) ->
      f_bid bid, List.map f_btype ts
    end
  in
  let f_btype_qual = function
    | #base_type_qual_t as qual -> qual
    | `Bound_needs_shape t -> `Bound_needs_shape (f_btype t)
  in
  match bbdcl with
  | BBDCL_module -> bbdcl
  | BBDCL_function (props,bvs,ps,res,es) ->
      BBDCL_function (props,f_bvs bvs,f_ps ps,f_btype res,List.map f_bexe es)
  | BBDCL_procedure (props,bvs,ps,es) ->
      BBDCL_procedure (props,f_bvs bvs,f_ps ps,List.map f_bexe es)
  | BBDCL_val (bvs,t) -> bbdcl_val (f_bvs bvs,f_btype t)
  | BBDCL_var (bvs,t) -> bbdcl_var (f_bvs bvs,f_btype t)
  | BBDCL_ref (bvs,t) -> bbdcl_ref (f_bvs bvs,f_btype t)
  | BBDCL_tmp (bvs,t) -> bbdcl_tmp (f_bvs bvs,f_btype t)
  | BBDCL_newtype (bvs,t) -> BBDCL_newtype (f_bvs bvs,f_btype t)
  | BBDCL_abs (bvs,quals,code,breqs) ->
      BBDCL_abs (f_bvs bvs,List.map f_btype_qual quals,code,f_breqs breqs)
  | BBDCL_const (props,bvs,t,code,breqs) ->
      BBDCL_const (props,f_bvs bvs,f_btype t,code,f_breqs breqs)
  | BBDCL_fun (props,bvs,ps,rt,code,breqs,prec) ->
      BBDCL_fun (
        props,
        f_bvs bvs,
        List.map f_btype ps,
        f_btype rt,
        code,
        f_breqs breqs,
        prec)
  | BBDCL_callback (props,bvs,ps_cf,ps_c,k,rt,breqs,prec) ->
      BBDCL_callback (
        props,
        f_bvs bvs,
        List.map f_btype ps_cf,
        List.map f_btype ps_c,
        k,
        f_btype rt,
        f_breqs breqs,
        prec)
  | BBDCL_proc (props,bvs,ps,code,breqs) ->
      BBDCL_proc (props,f_bvs bvs,List.map f_btype ps,code,f_breqs breqs)
  | BBDCL_insert (bvs,code,ikind,breqs) ->
      BBDCL_insert (f_bvs bvs,code,ikind,f_breqs breqs)
  | BBDCL_union (bvs,cs) ->
      BBDCL_union (f_bvs bvs,List.map (fun (n,i,t) -> n,i,f_btype t) cs)
  | BBDCL_struct (bvs,cs) ->
      BBDCL_struct (f_bvs bvs,List.map (fun (n,t) -> n,f_btype t) cs)
  | BBDCL_cstruct (bvs,cs) ->
      BBDCL_cstruct (f_bvs bvs,List.map (fun (n,t) -> n,f_btype t) cs)
  | BBDCL_typeclass (props,bvs) ->
      BBDCL_typeclass (props,f_bvs bvs)
  | BBDCL_instance (props,bvs,cons,bid,ts) ->
      BBDCL_instance (
        props,
        f_bvs bvs,
        f_btype cons,
        f_bid bid,
        List.map f_btype ts)
  | BBDCL_nonconst_ctor (bvs,uidx,ut,ctor_idx,ctor_argt,evs,etraint) ->
      BBDCL_nonconst_ctor (
        f_bvs bvs,
        f_bid uidx,
        f_btype ut,
        f_bid ctor_idx,
        f_btype ctor_argt,
        f_bvs evs,
        f_btype etraint)
  | BBDCL_axiom -> bbdcl
  | BBDCL_lemma -> bbdcl
  | BBDCL_reduce -> bbdcl

(* -------------------------------------------------------------------------- *)

let print_btype_qual f = function
  | #base_type_qual_t as qual ->
      print_base_type_qual f qual
  | `Bound_needs_shape t ->
      print_variant1 f "`Bound_needs_shape"
        Flx_btype.print t

let print_breqs f breqs =
  Flx_list.print begin fun f (bid, ts) ->
    print_tuple2 f print_bid bid (Flx_list.print Flx_btype.print) ts
  end f breqs

(** Convert the bound declaration to a string. *)
let rec print f = function
  | BBDCL_module -> print_variant0 f "BBDCL_module"
  | BBDCL_function (props,bvs,ps,res,es) ->
      print_variant5 f "BBDCL_function"
        print_properties props
        print_bvs bvs
        Flx_bparams.print ps
        Flx_btype.print res
        (Flx_list.print Flx_bexe.print) es
  | BBDCL_procedure (props,bvs,ps,es) ->
      print_variant4 f "BBDCL_procedure"
        print_properties props
        print_bvs bvs
        Flx_bparams.print ps
        (Flx_list.print Flx_bexe.print) es
  | BBDCL_val (bvs,t) ->
      print_variant2 f "BBDCL_val" print_bvs bvs Flx_btype.print t
  | BBDCL_var (bvs,t) ->
      print_variant2 f "BBDCL_var" print_bvs bvs Flx_btype.print t
  | BBDCL_ref (bvs,t) ->
      print_variant2 f "BBDCL_ref" print_bvs bvs Flx_btype.print t
  | BBDCL_tmp (bvs,t) ->
      print_variant2 f "BBDCL_tmp" print_bvs bvs Flx_btype.print t
  | BBDCL_newtype (bvs,t) ->
      print_variant2 f "BBDCL_newtype" print_bvs bvs Flx_btype.print t
  | BBDCL_abs (bvs,quals,code,reqs) ->
      print_variant4 f "BBDCL_abs"
        print_bvs bvs
        (Flx_list.print print_btype_qual) quals
        print_code_spec code
        print_breqs reqs
  | BBDCL_const (props,bvs,t,code,reqs) ->
      print_variant5 f "BBDCL_const"
        print_properties props
        print_bvs bvs
        Flx_btype.print t
        print_code_spec code
        print_breqs reqs
  | BBDCL_fun (props,bvs,ps,rt,code,reqs,prec) ->
      print_variant7 f "BBDCL_fun"
        print_properties props
        print_bvs bvs
        (Flx_list.print Flx_btype.print) ps
        Flx_btype.print rt
        print_code_spec code
        print_breqs reqs
        print_string prec
  | BBDCL_callback (props,bvs,ps_cf,ps_c,k,rt,reqs,prec) ->
      print_variant8 f "BBDCL_callback"
        print_properties props
        print_bvs bvs
        (Flx_list.print Flx_btype.print) ps_cf
        (Flx_list.print Flx_btype.print) ps_c
        pp_print_int k
        Flx_btype.print rt
        print_breqs reqs
        print_string prec
  | BBDCL_proc (props,bvs,ps,code,reqs) ->
      print_variant5 f "BBDCL_proc"
        print_properties props
        print_bvs bvs
        (Flx_list.print Flx_btype.print) ps
        print_code_spec code
        print_breqs reqs
  | BBDCL_insert (bvs,code,ikind,reqs) ->
      let ikind =
        match ikind with
        | `Header -> "header"
        | `Body -> "body"
        | `Package -> "package"
      in
      print_variant4 f "BBDCL_insert"
        print_bvs bvs
        print_code_spec code
        pp_print_string ikind
        print_breqs reqs
  | BBDCL_union (bvs,cs) ->
      print_variant2 f "BBDCL_union"
        print_bvs bvs
        (Flx_list.print begin fun f (n,i,t) ->
          print_tuple3 f
            print_string n
            pp_print_int i
            Flx_btype.print t
        end) cs
  | BBDCL_struct (bvs,cs) ->
      print_variant2 f "BBDCL_struct"
        print_bvs bvs
        (Flx_list.print begin fun f (n,t) ->
          print_tuple2 f
            print_string n
            Flx_btype.print t
        end) cs
  | BBDCL_cstruct (bvs,cs) ->
      print_variant2 f "BBDCL_cstruct"
        print_bvs bvs
        (Flx_list.print begin fun f (n,t) ->
          print_tuple2 f
            print_string n
            Flx_btype.print t
        end) cs
  | BBDCL_typeclass (props,bvs) ->
      print_variant2 f "BBDCL_typeclass"
        print_properties props
        print_bvs bvs
  | BBDCL_instance (props,bvs,cons,bid,ts) ->
      print_variant5 f "BBDCL_instance"
        print_properties props
        print_bvs bvs
        Flx_btype.print cons
        print_bid bid
        (Flx_list.print Flx_btype.print) ts
  | BBDCL_nonconst_ctor (bvs,uidx,ut,ctor_idx,ctor_argt,evs,etraint) ->
      print_variant7 f "BBDCL_nonconst_ctor"
        print_bvs bvs
        print_bid uidx
        Flx_btype.print ut
        print_bid ctor_idx
        Flx_btype.print ctor_argt
        print_bvs evs
        Flx_btype.print etraint
  | BBDCL_axiom -> print_variant0 f "BBDCL_axiom"
  | BBDCL_lemma -> print_variant0 f "BBDCL_lemma"
  | BBDCL_reduce -> print_variant0 f "BBDCL_reduce"
