(* pure OCaml coroutines using Oleg Kiselyov's delimited continuations *)

open Delimcc;;

(* ----------------------------------------------------------------------
   Coroutine operations
   ---------------------------------------------------------------------- *)

(* Coroutines with input 'i and output 'o *)
type ('i, 'o) coro = (('i->'o)ref * 'o prompt)

(* Coroutine monad (for use in coroutine bodies) *) 
type ('i,'o,'a) cm = (('i,'o) coro) -> ('a)

(* sugar: generator as a special coroutine *)
type 'o gen = (unit, 'o option) coro

(* create coroutine from body function *)
let create (f: 'i -> ('i,'o,'o) cm) : ('i,'o) coro =
  let p: 'o prompt = new_prompt() in
  let rec coro = ( ref (fun (x:'i) -> (f x) coro ), p)
  in coro

(* The current coroutine *)
let current (curcoro : ('i,'o) coro) : ('i,'o) coro = curcoro

(* Misuse of the coroutine mechanism *)
exception CoroutineError of string
  
(* Asymmetric coroutine operator: resume a suspended coroutine. *)
let resume (coro: ('ii,'oo) coro) (v: 'ii)  : 'oo = 
  let (pfun, pr) = coro in
  let new_f = !pfun in
  let () = pfun := (fun _-> (* prevent double-use of that continuation *) 
      raise (CoroutineError "attempt to activate a terminated or waiting coroutine")) 
  in
    push_prompt pr (fun () ->
		      new_f v)

(* Complement to resume: suspend the current coroutine, return to caller *)
let yield (v:'o) (state: ('i,'o) coro) : 'i = 
  let (pfun, pr) = state in
    shift pr (fun (k:('i->'o)) -> 
		pfun := k ;
		v)

(* Transfer control to another coroutine, suspending the current coroutine. *)
let transfer (coro: ('ii,'o) coro) (v: 'ii) (state: ('i,'o) coro) : 'i = 
  let (pfun, my_pr) = state in
    shift my_pr (fun (k: 'i->'o) -> 
		   pfun := k ;
		   let (otherpfun, other_pr) = coro in
		   let otherfun = !otherpfun in
		     push_prompt other_pr (fun () ->
					  otherfun v) )

(* ----------------------------------------------------------------------
   General monadery 
   ---------------------------------------------------------------------- *)


(* Inject a value into the monad *)
let return (v : 'a) (state : ('i,'o) coro) = v

(* Monad bind *)
let (>>=) (m : ('i,'o,'a) cm) (f : 'a -> ('i,'o,'b) cm) : ('i,'o,'b) cm =
  fun (state: ('i,'o) coro) ->
    (f (m state)) state

(* Monad bind, discarding the value *)
let (>>) (m :  ('i,'o,'a) cm) (g : ('i,'o,'b) cm) : ('i,'o,'b) cm =
  m >>= (fun _ -> g)



(* ----------------------------------------------------------------------
   Utilities
   ---------------------------------------------------------------------- *)

(* the items of a generator as a list *)
let rec list_of_gen (g: (unit, 'a option) coro) : 'a list = 
  match resume g () with
    | None -> []
    | Some x -> x :: (list_of_gen g)

(* a coro body for a coroutine which returns one value *)
let once (x:'o) : 'i -> ('i,'o,'o) cm = fun _ -> return x

(* coro body which generates the elements of that list *)
let gen_of_list_f (xs: 'a list) : unit-> (unit, 'a option, 'a option) cm =
  let rec loop (xs: 'a list) () : (unit,'a option,'a option) cm = 
    match xs with
      | [] -> return None
      | y::ys -> (yield (Some y)) >>= (loop ys)
  in loop xs 

(* convert from list to generator *)
let make_list_gen (xs : 'a list) : 'a gen =
  create (gen_of_list_f xs)

(* call a side-effect-function for each generated element *)
let iter_gen (gen: 'a gen) (f:'a -> unit) : unit =
  let rec loop () =
    match (resume gen ()) with
      | None -> ()
      | Some x -> (f x) ; loop ()
  in loop ()
