type 'a syscall_t =
  | RandomBytes of 'a
  | ExternFunc of string * Type.atype list * Type.atype list

