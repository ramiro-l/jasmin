type 'ty syscall_t =
  | RandomBytes of Wsize.wsize * BinNums.coq_Z
  | ExternFun of string * 'ty list * 'ty list
