(* Copyright (c) 2015, SRI International

   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation files
   (the "Software"), to deal in the Software without restriction,
   including without limitation the rights to use, copy, modify, merge,
   publish, distribute, sublicense, and/or sell copies of the Software,
   and to permit persons to whom the Software is furnished to do so,
   subject to the following conditions:
   
   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
   OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
   WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*)

(*
 *  Compilation Units
 *)

open Llvm
 
type linkage =
  | Extern_weak
  | External
  | Private
  | Internal
  | Weak
  | Weak_odr
  | Linkonce
  | Linkonce_odr
  | Available_externally
  | Appending
  | Common

type visibility =
  | Default
  | Hidden
  | Protected

type dll_storageclass =
  | Dllimport
  | Dllexport

type aliasee =
  | A_bitcast       of (typ * value) * typ
  | A_getelementptr of bool * (typ * value) list
  | A_typ_value     of (typ * value)


(*
 * Symbol tables, aka contexts: map vars to types
 * - each function has a context
 * - each compilation unit has both a
 *   local (for e.g. types) and a global context.
 *)
type vtbl = (var, typ) Hashtbl.t

(* blocks *)
type binfo = {
  mutable bname: var;
  mutable binstrs: (var option * instr) list;
  (* used to mark when a block has been see/processed *)
  mutable bseen: bool;
  (* used to store the position of this block in the finfo fblocks list
   * n.b. this is not always the same as its label because of unnamed parameters
   * in function (see fcounter).
   *)
  mutable bindex: int;
  mutable brank: int;
  (*
   * Index of the memory state when this block was exited
   *)
  mutable bmem: int
}

(*
 * Edge in the control flow graph.
 * Given a block b, we keep track of its predecessors
 * (i.e., the blocks that end with a branch instructions to b)
 * and the conditions under which the branch is taken.
 *
 * Conditions:
 *   Uncond             --> no conditions (i.e., the condition is true)
 *   Eq tau, var, const --> var == const (and both var and const have type tau)
 *   Distinct tau, var, [c1, ..., c_n]  --> (var != c1 & var != c2 & ... & var != c_n)
 *
 * These conditions are enough to handle the br and switch instructions.
 *
 * For invoke and indirect branch, we label the condition as Unsupported.
  *
 * An edge is a pair (source, condition) where source is the name of source block.
 *)
type cfg_condition = 
  | Uncond
  | Eq of typ * value * value
  | Distinct of typ * value * value list
  | Unsupported

type cfg_edge = var * cfg_condition

type cfg_neighbors = (var, cfg_edge) Hashtbl.t


(*
 * Function parameters:
 * the boolean flag is to support functions with variable numbers
 * of arguments (varargs stuff):
 * - if the flag is true, the parameter list ends with ... (variadic function)
 *)
type function_parameters = (typ * param_attribute list * var option) list * bool

(* functions *)
type finfo = {
  fcounter: int ref;  (* counter used to produce local variables and types *)
  context: vtbl;      (* local symbol table *)
  cfg_predecessors: cfg_neighbors;
  cfg_successors: cfg_neighbors;
  mutable flinkage: linkage option;
  mutable fvisibility: visibility option;
  mutable fstorageclass: dll_storageclass option;
  mutable fcallingconv: callingconv option;
  mutable freturnattrs: return_attribute list;
  mutable freturntyp: typ;
  mutable fname: var;
  mutable fparams: function_parameters;
  mutable funnamed_addr: bool;
  mutable fattrs: function_attribute list;
  mutable fsection: string option;
  mutable falign: int option;
  mutable fgc: string option;
  mutable fprefix: (typ * value) option;
  mutable fblocks: binfo list;
}

type thread_local =
  | Localdynamic
  | Initialexec
  | Localexec

(* global variables *)
type ginfo = {
  mutable gname: var;
  mutable glinkage: linkage option;
  mutable gvisibility: visibility option;
  mutable gstorageclass: dll_storageclass option;
  mutable gthread_local: thread_local option option;
  mutable gaddrspace: int option;
  mutable gunnamed_addr: bool;
  mutable gexternally_initialized: bool;
  mutable gconstant: bool;
  mutable gtyp: typ; (* actual type of the global is a pointer to this type *)
  mutable gvalue: value option;
  mutable gsection: string option;
  mutable galign: int option;
}

(* aliases *)
type ainfo = {
  aname: var;
  avisibility: visibility option;
  alinkage: linkage option;
  aaliasee: aliasee
}

(* metadata *)
type mdinfo = {
  mdid: int;
  mdtyp: typ;
  mdcontents: (typ * value) option list;
}

(* compilation unit *)
type cunit = {
  gcontext: vtbl; (* symbol table for global symbols *)
  lcontext: vtbl; (* symbols local to the cu (e.g., types and structs) *)
  dl: Dl.datalayout;  (* deconstruction of the (c)datalayout string  *)
  mutable cdatalayout: string option;
  mutable ctarget: string option;
  mutable casms: string list;
  mutable ctyps: (var * typ option) list;
  mutable cglobals: ginfo list;
  mutable caliases: ainfo list;
  mutable cfuns: finfo list;
  mutable cattrgrps: (int * attribute list) list;
  mutable cmdvars: (string * int list) list;
  mutable cmdnodes: mdinfo list;
}
