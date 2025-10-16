#
# Spécifique au Projet
#

PROJECT ?= dbase2
BUILD_PATH = ../build
OBJ_PATH = $(BUILD_PATH)/obj
BIN_PATH = $(BUILD_PATH)/bin
LIB_PATH = $(BUILD_PATH)/lib
LIB_EXT_PATH = ../lib
LD65_CFG = ../cfg/dbase2.cfg

KERNEL_PATH = ../../orix-software/
SHELL_PATH = ../../orix-software/
SDK_PATH = ../../orix-sdk/
SDK_LIB_PATH = $(SDK_PATH)/build/lib

LIBS = $(SDK_LIB_PATH)/orix-sdk.lib $(LIB_EXT_PATH)/readline.lib $(LIB_EXT_PATH)/dbf.lib $(LIB_EXT_PATH)/fns.lib $(SDK_LIB_PATH)/orix-sdk.lib
# LIBS = $(SDK_LIB_PATH)/orix-sdk.lib $(LIB_EXT_PATH)/readline.lib

START_ADDR ?= 0x0900

VERSION ?= "0.01"
VERBOSE ?= 0

PGM_MODE ?= "DBASE2"

# %<-------------------------------------------------------------------------->%
#               Ne rien modifier au dela de cette ligne
#
TARGET = telestrat

#
# Définition des outils
#

ifeq ($(CC65_HOME),)
	CC = cc65
	AS = ca65
	LD = ld65
	AR = ar65
else
	CC = $(CC65_HOME)/bin/cc65
	AS = $(CC65_HOME)/bin/ca65
	LD = $(CC65_HOME)/bin/ld65
	AR = $(CC65_HOME)/bin/ar65
endif

#
# Définition du fichier de configuration de ld65
#
ifeq ($(LD65_CFG),)
	LD65_CFG = -t $(TARGET)
else
	LD65_CFG := -C $(LD65_CFG)
endif

#
# Définition des options pour les outils
#

ifeq ($(DEBUG),yes)
	#  ASFLAGS = -t $(TARGET) -I ../ -I . -I $(SDK_PATH)/macros -I $(SDK_PATH)/include -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE) --auto-import --list-bytes 0 -l $(@:.o=.lst) --debug-info
	ASFLAGS = -t $(TARGET) -I ../ -I . -I $(SDK_PATH)/macros -I $(SDK_PATH)/include -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE) --list-bytes 0 -l $(@:.o=.lst) --debug-info -D $(PGM_MODE)
	LDFLAGS = $(LD65_CFG)  -Ln $(@).ca.sym -m $(@).map --lib-path $(SDK_LIB_PATH) --lib-path $(LIB_PATH) --lib-path $(LIB_EXT_PATH) --start-addr $(START_ADDR)
	# LDFLAGS = -C "$(LD65_CFG)"  -Ln $(BUILD_PATH)/$(PROJECT).ca.sym -m $(BUILD_PATH)/$(PROJECT).map --lib-path $(SDK_LIB_PATH)
else
	ASFLAGS = -t $(TARGET) -I ../ -I . -I $(SDK_PATH)/macros -I $(SDK_PATH)/include -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE) --auto-import -D $(PGM_MODE)
	LDFLAGS = $(LD65_CFG)  --lib-path $(SDK_LIB_PATH) --lib-path $(LIB_PATH) --lib-path $(LIB_EXT_PATH) --start-addr $(START_ADDR)
	# LDFLAGS = -C "$(LD65_CFG)"  --lib-path $(SDK_LIB_PATH)
endif

CREATE_DEP = --create-dep $(@:.o=.d)

#
# Cibles make
#

#.PHONY: clean mrproper $(SUBDIRS)


all: $(BUILD_PATH) $(OBJ_PATH) $(BIN_PATH) $(LIB_PATH) $(BIN_PATH)/$(PROJECT) $(SUBDIRS)


configure: $(OBJ_PATH) $(BIN_PATH) $(LIB_PATH)


clean:
	@cd $(OBJ_PATH) && rm -f *.o *.lst *.d
	@cd $(OBJ_PATH)/cmnds && rm -f *.o *.lst *.d
	@cd $(OBJ_PATH)/fns && rm -f *.o *.lst *.d
	@cd $(OBJ_PATH)/lex && rm -f *.o *.lst *.d
	@cd $(OBJ_PATH)/utils && rm -f *.o *.lst *.d
	@cd $(BIN_PATH) && rm -f *.sym *.map


mrproper: clean
	@rm -rf $(BIN_PATH)
	@rm -rf $(OBJ_PATH)
	@rm -rf $(LIB_PATH)


#
# Règles Make
#


SRC = $(wildcard *.s)
SRC_FNS = $(wildcard fns/*.s)
SRC_CMNDS = $(wildcard cmnds/*.s)
SRC_LEX = $(wildcard lex/*.s)
SRC_UTILS = $(wildcard utils/*.s)

OBJS = $(addprefix $(OBJ_PATH)/, $(patsubst %.s,%.o, $(SRC)))
OBJS_FNS = $(addprefix $(OBJ_PATH)/, $(patsubst %.s,%.o, $(SRC_FNS)))
OBJS_CMNDS = $(addprefix $(OBJ_PATH)/, $(patsubst %.s,%.o, $(SRC_CMNDS)))
OBJS_LEX = $(addprefix $(OBJ_PATH)/, $(patsubst %.s,%.o, $(SRC_LEX)))
OBJS_UTILS = $(addprefix $(OBJ_PATH)/, $(patsubst %.s,%.o, $(SRC_UTILS)))

DEPS := $(OBJS:.o=.d)

#%.o: %.s
$(OBJ_PATH)/%.o: %.s
	@echo -e "\nAssemble $<"
	@$(AS) $(ASFLAGS) $(CREATE_DEP) -o $@ $<


$(BIN_PATH)/$(PROJECT): $(OBJS) $(LIB_PATH)/cmnds.lib $(LIB_PATH)/fns.lib $(LIB_PATH)/lex.lib $(LIB_PATH)/utils.lib $(LIB_PATH)/cmnds.lib $(LIBS)
	@echo -e "\nCreate $(PROJECT) (start address = $(START_ADDR))"
	$(LD) $(LDFLAGS) -o $@ $+ $(TARGET).lib
ifeq ($(DEBUG),yes)
	@echo "Create $(PROJECT).sym"
	@sed -re 's/al 00(.{4}) \.(.+)$$/\1 \2/' $(BIN_PATH)/$(PROJECT).ca.sym | sort | uniq > $(BIN_PATH)/$(PROJECT).sym
endif


# $(LIB_PATH)/%.lib: $(OBJ_PATH)/%/*.o
#	@echo "Create $@ library"
#	@$(AR) r $@ $^

$(LIB_PATH)/fns.lib: $(OBJS_FNS)
	@echo -e "\nCreate $@ library"
	@$(AR) r $@ $^


$(LIB_PATH)/cmnds.lib: $(OBJS_CMNDS)
	@echo -e "\nCreate $@ library"
	@$(AR) r $@ $^

$(LIB_PATH)/lex.lib: $(OBJS_LEX)
	@echo -e "\nCreate $@ library"
	@$(AR) r $@ $^

$(LIB_PATH)/utils.lib: $(OBJS_UTILS)
	@echo -e "\nCreate $@ library"
	@$(AR) r $@ $^

$(LIB_PATH):
	@echo "Create $(LIB_PATH) directory"
	@mkdir -p $(LIB_PATH)

$(OBJ_PATH):
	@echo "Create $(OBJ_PATH) directory"
	@mkdir -p $(OBJ_PATH) $(OBJ_PATH)/cmnds
	@mkdir -p $(OBJ_PATH) $(OBJ_PATH)/fns
	@mkdir -p $(OBJ_PATH) $(OBJ_PATH)/lex
	@mkdir -p $(OBJ_PATH) $(OBJ_PATH)/utils

$(BIN_PATH):
	@echo "Create $(BIN_PATH) directory"
	@mkdir -p $(BIN_PATH)

$(BUILD_PATH):
	@echo "Create $(BUILD_PATH) directory"
	@mkdir -p $(BUILD_PATH)

-include $(DEPS)

.PHONY: clean mrproper $(SUBDIRS)

