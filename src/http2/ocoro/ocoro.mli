(* pure OCaml coroutines using Oleg Kiselyov's delimited continuations *)

(* Coroutines with input 'i and output 'o *)
type ('i,'o) coro
(* Coroutine monad (for use in coroutine bodies) *) 
type ('i,'o,'a) cm
(* sugar: generator as a special coroutine *)
type ('a) gen = (unit, 'a option) coro

(* Inject a value into the monad *)
val return : 'a -> ('i,'o,'a) cm
(* Monad bind *)
val (>>=) : ('i,'o,'a) cm -> ('a -> ('i,'o,'b) cm) -> ('i,'o,'b) cm
(* Monad bind, discarding the value *)
val (>>) : ('i,'o,'a) cm -> ('i,'o,'b) cm -> ('i,'o,'b) cm

(* create coroutine from body function *)
val create : ('i -> ('i,'o,'o) cm) -> ('i,'o) coro
(* The current coroutine *)
val current : ('i,'o, ('i,'o) coro) cm
(* Misuse of the coroutine mechanism *)
exception CoroutineError of string
(* Asymmetric coroutine operator: resume a suspended coroutine. *)
val resume: ('i,'o) coro -> 'i -> 'o
(* Complement to resume: suspend the current coroutine, return to caller *)
val yield : 'o -> ('i,'o,'i) cm 
(* Transfer control to another coroutine, suspending the current coroutine. *)
val transfer : ('ii,'o) coro -> 'ii -> ('i,'o,'i) cm

(* the items of a generator as a list *)
val list_of_gen :  'a gen -> 'a list 
(* convert from list to generator *)
val make_list_gen : 'a list -> 'a gen
(* call a side-effect-function for each generated element *)
val iter_gen : 'a gen -> ('a -> unit) -> unit

(* a coro body for a coroutine which returns one value *)
val once : 'o -> 'i -> ('i,'o,'o) cm 
