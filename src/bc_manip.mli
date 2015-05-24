(*
 * LLVM bitcode post parsing processing tools.
 *)

(*
 * Goes through all the function definitions in the cunit and makes sure each finfo.fcounter is correct.
 * This is necessary because C++ has unnamed parameters, and these get replaced by %0, %1, .... %n.
 *  (So we can't assume that the first block of every function has label %0).
 *)
val process_params: Bc.cunit -> unit


(*
 * Assign a label to every block.
 *
 * Blocks may not have explicit names (labels) when parsed.  Any
 * unnamed block is assigned name Id(false,-1) by the parser.  This
 * function finds a correct name.
 * 
 * Must be called after process_params.
 *)
val assign_block_numbers: Bc.cunit -> unit

(*
 * Contexts + global variable table
 * - each compilation units has two symbol tables:
 *   the gcontext stores type information for all the global variables
 *   the lcontext stores type definitions local the unit (for local
 *   types and structs)
 * - each function unit also has a local symbol table (context)
 *   that stores the type information for all the variables local to
 *  the function.
 *
 * Function assign_vartyps fills in these tables.
 * Function typ_of_var queries the type of a variable by reading these tables.
 *)

val assign_vartyps: Bc.cunit -> unit


(*
 * (typ_of_var c f v) --> type of variable v 
 * v must be defined in function f or module c.
 *
 * If v is a global name, this looks in c.gcontext.
 * If v is a local name, this looks first in f.context 
 * then in c.lcontext.
 *
 * Fails with an exception if v is not found in
 * any of these tables.
 *)
val typ_of_var: Bc.cunit -> Bc.finfo -> Llvm.var -> Llvm.typ

(*
 * value_to_var t --> checks whether t is a var or basicbloack 
 * name and returns the name.
 *
 * Fails with an exception if t is not a var or basicblock.
 *)
val value_to_var: Llvm.value -> Llvm.var

(*
 * Compute the predecessor tables of each funit in 
 * a compilation unit.
 *
 *)
val compute_neighbors: Bc.cunit -> unit

val get_predecessors: Bc.finfo -> Llvm.var -> Llvm.var list 
    
val get_successors: Bc.finfo -> Llvm.var -> Llvm.var list

val print_neighbors: Bc.neighbors -> unit

(*
 * Compute the cfg predecessor tables of each funit in 
 * a compilation unit.
 *)
val compute_cfg_predecessors: Bc.cunit -> unit


(*
 * Get a block given its name.
 *)
val lookup_block: Bc.finfo -> Llvm.var -> Bc.binfo
    
