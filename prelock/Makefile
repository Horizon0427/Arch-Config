CC ?= cc
CFLAGS ?= -O2
CPPFLAGS += -Iinclude

TARGET := prelock
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share/prelock
SHADERDIR := $(DATADIR)/shaders
SOURCES := \
	src/main.c \
	src/prelock.c \
	src/palette.c \
	src/easing.c \
	src/desktop_capture.c \
	src/components/lock_icon.c \
	src/animations/registry.c \
	src/animations/classic.c \
	src/animations/swift.c \
	src/animations/diagonal.c \
	src/animations/meteor.c \
	src/animations/liquid.c

HEADERS := \
	include/prelock/animation.h \
	include/prelock/prelock.h \
	include/prelock/palette.h \
	include/prelock/easing.h \
	include/prelock/desktop_capture.h \
	include/prelock/components/lock_icon.h \
	include/prelock/animations/registry.h \
	include/prelock/animations/classic.h \
	include/prelock/animations/swift.h \
	include/prelock/animations/diagonal.h \
	include/prelock/animations/meteor.h \
	include/prelock/animations/liquid.h

WARNINGS := -Wall -Wextra -Wpedantic -Wconversion -Wshadow
LDLIBS += -lraylib -lm

.PHONY: all clean install

all: $(TARGET)

$(TARGET): $(SOURCES) $(HEADERS)
	$(CC) $(CPPFLAGS) $(CFLAGS) -std=c11 $(WARNINGS) $(SOURCES) \
		$(LDFLAGS) $(LDLIBS) -o $@

install: $(TARGET)
	install -d "$(BINDIR)" "$(SHADERDIR)"
	install -m755 "$(TARGET)" "$(BINDIR)/$(TARGET).new"
	mv -f "$(BINDIR)/$(TARGET).new" "$(BINDIR)/$(TARGET)"
	install -m644 assets/shaders/liquid_glass.fs \
		"$(SHADERDIR)/liquid_glass.fs.new"
	mv -f "$(SHADERDIR)/liquid_glass.fs.new" \
		"$(SHADERDIR)/liquid_glass.fs"

clean:
	$(RM) $(TARGET)
