From elpi.apps Require Import derive.std.
From HB Require Import structures.
From mathcomp Require Import ssreflect ssrfun ssrbool seq eqtype ssralg.
From Coq Require Import PArith ZArith.
Require Import strings.
Require Import
  word
  type
  utils.

#[only(eqbOK)] derive
Variant syscall_t : Type := 
  | RandomBytes of wsize & Z
  | ExternFunc of string & seq atype & seq atype.

HB.instance Definition _ := hasDecEq.Build syscall_t syscall_t_eqb_OK.

(* -------------------------------------------------------------------- *)
(* For typing                                                           *)

(* Before stack alloc ie uprog *)

Record syscall_sig_t := {
  scs_tin  : seq atype;
  scs_tout : seq atype
}.

Definition syscall_sig_u (o : syscall_t) : syscall_sig_t := 
  match o with
  | RandomBytes ws len => {| scs_tin := [:: aarr ws len]; scs_tout := [:: aarr ws len] |}
  | ExternFunc _ args rets => {| scs_tin := args; scs_tout := rets |}
  end.

(* After stack alloc ie sprog *)
Definition syscall_sig_s {pd:PointerData} (o:syscall_t) : syscall_sig_t := 
  match o with
  | RandomBytes _ _ => {| scs_tin := [::aword Uptr; aword Uptr]; scs_tout := [::aword Uptr] |}
  | ExternFunc _ args rets => {| scs_tin := args; scs_tout := rets |} (* FIXME: esto no es correcto *)
  end.


(* -------------------------------------------------------------------- *)
(* For the semantic                                                     *)
Class syscall_sem (syscall_state : Type) := {
  get_random : syscall_state -> Z -> syscall_state * seq u8
}.


Definition syscall_state_t {syscall_state : Type} {sc_sem: syscall_sem syscall_state} := syscall_state.
