
BUILDDIR := build
BINDIR := .
SRCDIR := src

BUILD := debug
optimization.sanitize := -fsanitize=address -O1 -fno-omit-frame-pointer
optimization.debug := -O0 -g3
optimization.release := -O2 -flto # -DNDEBUG -Wno-return-type

SOURCES := $(wildcard $(SRCDIR)/*.cpp) $(wildcard $(SRCDIR)/crab/*.cpp)
ALL_OBJECTS := $(SOURCES:$(SRCDIR)/%.cpp=$(BUILDDIR)/%.bc)
DEPENDS := $(ALL_OBJECTS:%.bc=%.d)

TEST_SOURCES := $(wildcard $(SRCDIR)/test*.cpp)
TEST_OBJECTS := $(TEST_SOURCES:$(SRCDIR)/%.cpp=$(BUILDDIR)/%.bc)

MAIN_SOURCES := $(wildcard $(SRCDIR)/main_*.cpp)
MAIN_OBJECTS := $(MAIN_SOURCES:$(SRCDIR)/%.cpp=$(BUILDDIR)/%.bc)

OBJECTS := $(filter-out $(MAIN_OBJECTS) $(TEST_OBJECTS),$(ALL_OBJECTS))

LDFLAGS += --emrun --preload-file ebpf-samples

LINUX := $(abspath ../linux)

LDLIBS +=

CXXFLAGS := -Wall -Wfatal-errors -std=c++17 -DSIZEOF_VOID_P=8 -DSIZEOF_LONG=8 -I $(SRCDIR) -I external -I /usr/local/Cellar/boost/1.70.0/include -I /usr/local/Cellar/gmp/6.1.2_2/include  # -s DISABLE_EXCEPTION_CATCHING=0
CXXFLAGS += ${optimization.${BUILD}}

all: $(BINDIR)/check.html  # $(BINDIR)/unit-test



$(BUILDDIR)/%.bc: $(SRCDIR)/%.cpp
	@mkdir -p $(dir $@)
	@printf "$@ <- $<\n"
	@$(CXX) $(CXXFLAGS) $< -MMD -MP -c -o $@ # important: use $< and not $^

$(BINDIR)/unit-test: $(BUILDDIR)/test.bc $(TEST_OBJECTS) $(OBJECTS)
	@printf "$@ <- $^\n"
	@$(CXX) $(CXXFLAGS) $(LDFLAGS) $^ $(LDLIBS) -o $@

$(BINDIR)/check.html: $(BUILDDIR)/main_check.bc $(OBJECTS)
	@printf "$@ <- $^\n"
	@$(CXX) $(CXXFLAGS) $(LDFLAGS) $^ $(LDLIBS) -o $@

clean:
	rm -f $(BINDIR)/check* $(BINDIR)/unit-test
	rm -rf $(BUILDDIR)

linux_samples:
	git clone --depth 1 https://github.com/torvalds/linux.git $(LINUX)
	make -C $(LINUX) headers_install
	make -C $(LINUX) oldconfig < /dev/null
	make -C $(LINUX) samples/bpf/

html: $(SRCDIR)/*.*pp $(SRCDIR)/*/*/*.*pp
	doxygen

print-% :
	@echo $* = $($*)

-include $(DEPENDS)
