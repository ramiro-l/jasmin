JASMINC=../../../../../jasminc

JAZZ=main.jazz
C_SRC=main.c

ASM_DIR=build/asm
OBJ_DIR=build/obj

BIN=main

all:
	mkdir -p $(ASM_DIR) $(OBJ_DIR)
	$(JASMINC) -o $(ASM_DIR)/$(JAZZ:.jazz=.s) $(JAZZ)
	as -o $(OBJ_DIR)/$(JAZZ:.jazz=.o) $(ASM_DIR)/$(JAZZ:.jazz=.s)
	gcc -c $(C_SRC) -o $(OBJ_DIR)/$(C_SRC:.c=_main.o)
	gcc -o $(BIN) $(OBJ_DIR)/$(JAZZ:.jazz=.o) $(OBJ_DIR)/$(C_SRC:.c=_main.o)

run: all
	./$(BIN)

clean:
	rm -rf build $(BIN)
