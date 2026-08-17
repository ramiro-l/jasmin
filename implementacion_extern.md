# Implementación de funciones `extern` — Fase 1 (Lexer + AST + Parser)

> Documento de seguimiento del proceso de implementación. Se actualiza fase a fase
> en orden estricto del compilador: **Lexer → AST → Parser → Downstream (typing/printer)**.

---

## Objetivo

Permitir que el compilador Jasmin parseee y construya el AST de declaraciones de
funciones **sin cuerpo** usando la palabra clave `extern`:

```
extern fn add(reg u64 x, reg u64 y) -> reg u64;
```

El punto de partida: la sintaxis de argumentos `(reg u64 x, reg u64 y)` y de retorno
`-> reg u64` ya está soportada para funciones normales. El bloqueante era la palabra
`extern` y la ausencia de cuerpo.

---

## Enfoque (directiva del director)

- **No** tocar `pfundef` (la definición de funciones normales).
- Crear un **nuevo `top` `externdef`** y un **nuevo constructor `PExterndef`** en el AST.
- Referencias clave apuntadas por el director:
  - `pretyping.ml ~2046`: case especial "dirty" de `randombytes` (`PEPrim → Csyscall`),
    el mecanismo actual que esta declaración viene a formalizar.
  - `proofs/lang/expr.v:419`: tipo `instr_r` en Coq (`Csyscall : lvals -> syscall_t -> pexprs`).
  - Ejemplo: `compiler/tests/success/x86-64/randombytes_length_0.jazz` (usa `#randombytes`).
- **Numeral / etiqueta** (`@add(1,3)` o `!#`): se deja para una fase futura
  (analizar colisiones entre llamadas).

---

## Entorno y comandos

| Acción | Comando |
|---|---|
| Entrar al entorno | `nix-shell --pure --arg pinned-nixpkgs true` |
| Compilar | `cd compiler && make` |
| Ejecutar sobre el test | `./jasminc ../test.jazz` |
| Frontend temprano | `./jasminc -ptyping ../test.jazz` (o `-until_typing`) |

> Los flags `-ptyping` / `-until_typing` se generan dinámicamente en `glob_options.ml`
> a partir de `Compiler.compiler_step_list`.

---

## Archivo de prueba `test.jazz`

```
extern fn add(reg u64 x, reg u64 y) -> reg u64;
```

---

## Fase 1 — Qué se modificó y por qué

> **Nota importante:** Menhir se compila con `--strict`, que convierte un **token no
> usado en un ERROR** (no en un warning). Por eso el token `EXTERN` y la regla
> `externdef` se añadieron juntos: era imposible dejar el token declarado sin usarlo.
> En la práctica esto unificó la "Fase 1 (Lexer+AST)" con la "Fase 2 (Parser)".

### 1. `compiler/src/lexer.mll` — Lexer
- Se añadió la keyword a la tabla `_keywords`:
  ```ocaml
  "export", EXPORT ;
  "extern", EXTERN ;
  ```
- Se añadió un **print de debug temporal** en la regla `ident` para verificar:
  ```ocaml
  | ident as s
      { let t = Option.default (NID s) (Hash.find_option keywords s) in
        if s = "extern" then
          Format.eprintf "DEBUG lexer: `%s` -> token EXTERN@." s;
        t }
  ```
- **Por qué:** sin esto, `extern` se lexeaba como un identificador `NID "extern"` y el
  parser lo trataba de forma confusa. Ahora es un token dedicado y distinguible.

### 2. `compiler/src/parser.mly` — Parser (Menhir)
- Declaración del token:
  ```ocaml
  %token EXTERN
  ```
- Nueva regla `externdef` (colocada después de `pfundef`):
  ```ocaml
  externdef:
  | EXTERN FN
      name = ident
      args = parens_tuple(annot_pparamdecl)
      rty  = prefix(RARROW, tuple(annot_stor_type))?
      SEMICOLON
    { { pex_name = name;
        pex_args = args;
        pex_rty  = rty ; } }
  ```
- Nuevo caso en la regla `top`:
  ```ocaml
  | x=externdef { Syntax.PExterndef x }
  ```
- **Por qué:** define la sintaxis `extern fn nombre(args) -> rty;` y produce el nodo AST.

### 3. `compiler/src/syntax.ml` — AST
- Nuevo tipo de declaración externa (sin cuerpo):
  ```ocaml
  (* Declaración de función externa (sin cuerpo). *)
  type pexterndef = {
    pex_name : pident;
    pex_args : (pannotations * paramdecls) list;
    pex_rty  : (pannotations * pstotype) list option;
  }
  ```
- Nuevo constructor en `pitem`:
  ```ocaml
  type pitem =
    | PFundef of pfundef
    | PExterndef of pexterndef
    | PParam of pparam
    ...
  ```
- **Por qué:** representa la declaración externa como un item de top-level propio,
  sin contaminar `pfundef`.

### 4. `compiler/src/pretyping.ml` — placeholder (typing)
- En `tt_item`, se añadió un caso para que el match exhaustivo siga compilando:
  ```ocaml
  | S.PExterndef _ ->
      (* TODO (Fase 3): registrar la función externa / símbolo *)
      env
  ```
- **Por qué:** `tt_item` hace match exhaustivo sobre `S.pitem`; sin este caso no compila.
  El comportamiento real se define en la Fase 3.

### 5. `compiler/src/latex_printer.ml` — placeholder (printer LaTeX)
- En `pp_pitem`, se añadió:
  ```ocaml
  | PExterndef _ -> ()
  ```
- **Por qué:** mismo motivo (match exhaustivo). Imprimir la firma se hará en la Fase 3.

---

## Verificación de la Fase 1

1. `nix-shell --pure --arg pinned-nixpkgs true`
2. `cd compiler && make` → **compila sin errores**.
3. `./jasminc ../test.jazz` →
   ```
   DEBUG lexer: `extern` -> token EXTERN
   ```
   Sin error de sintaxis → **el parser construye el `PExterndef`**.
4. `./jasminc -ptyping ../test.jazz` → llega a *"After typing"* sin crashear
   (el `externdef` se ignora por ahora en typing).

---

## Aprendizajes / notas

- Menhir con `--strict` trata los **tokens no usados como error**. Al añadir un token
  nuevo, hay que usarlo en la gramática en el mismo cambio.
- Al añadir un constructor a un tipo algebraico con matchs exhaustivos (`S.pitem`),
  hay que actualizar **todos** los matchs (encontrados en `pretyping.ml` y
  `latex_printer.ml`).
- La rama `exp/02-syntax` estaba vacía (sin commits), por lo que se partió de cero
  sobre el estado actual del repo.

---

## Pendiente — Fase 3 (downstream)

- [ ] `pretyping.ml`: dar semántica real al `externdef` (declarar el símbolo para que
      las llamadas lo resuelvan; ver el case de `randombytes` ~2046).
- [ ] `latex_printer.ml` / `printer.ml`: imprimir `extern fn ...;`.
- [ ] Limpiar el print de debug del lexer.
- [ ] Analizar numeral / etiqueta de llamadas (`@add(1,3)` o `!#`) — fase futura.
