type 'a syscall_t =
  | RandomBytes of 'a
  | ExternFun of string * Type.atype list * Type.atype list
