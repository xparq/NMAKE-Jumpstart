SRC_DIR=.


#-----------------------------------------------------------------------------
# Internals...
#-----------------------------------------------------------------------------
BUILDER_TOOL_DIR=tmp
BUILDER_THIS_MAKEFILE=Makefile
#-----------------------------------------------------------------------------
toolname=buildtool
toolsrc=$(BUILDER_TOOL_DIR)\$(toolname).cpp
toolfile=$(BUILDER_TOOL_DIR)\$(toolname).exe
tool=$(toolfile) # Just a comfy shorthand
KK=<< # Replace the << ops with $(KK) in the C++ code, otherwise NMAKE gets confused! :-o


#-----------------------------------------------------------------------------
# Rules
#-----------------------------------------------------------------------------
.PHONY: all bootstrap build_job
all: bootstrap build_job

build_job:
	$(tool) $(SRC_DIR)


bootstrap: $(tool)
$(tool): $(BUILDER_THIS_MAKEFILE)
$(tool):
	@if not exist "$(BUILDER_TOOL_DIR)" md "$(BUILDER_TOOL_DIR)"
	$(CC) /nologo /EHsc /std:c++20 /MD /Fe$(toolfile) /Fo$(BUILDER_TOOL_DIR)\ <<$(toolsrc)
#include <filesystem>
#include <vector>
#include <iostream>
#include <string_view>
#include <format>
using namespace std;
namespace fs = filesystem;
using fs::path;

#define NL '\n'
#define SP ' '

void  print( string_view  s) {  cout<< s <<NL; }
void  print(wstring_view  s) { wcout<< s <<NL; }
void eprint( string_view  s) {  cerr<< s <<NL; }
void eprint(wstring_view  s) { wcerr<< s <<NL; }
void  print(const path&   p) { wcout<< p.native() <<NL; }
void eprint(const path&   p) { wcerr<< p.native() <<NL; }
void  print(const char*   s) {  print(string_view(s)); }
void eprint(const char*   s) { eprint(string_view(s)); }
void  print(const string& s) {  print(string_view(s)); }
void eprint(const string& s) { eprint(string_view(s)); }

string str(const auto& entry) { return entry.path().string(); }

void TraverseDir(const path& dirPath, const path& root = "") {
	if (root == "") {
		const_cast<path&>(root) = dirPath;
	}
	for (const auto& entry : fs::directory_iterator(dirPath)) {
		if (entry.is_directory()) {
			path subdir = fs::relative(entry, root); // Remove root prefix
//			print(format("root: {}: raw {} -> subdir {}", root.string(), entry.path().string(), subdir.string()));
			print(subdir);
			TraverseDir(str(entry), root);
		} else if (entry.is_regular_file()) {
			// If it's a regular file, do something with it
			//eprint(format(" - file: {}", str(entry)));
		}
	}
}

//-----------------------------
int main(int argc, char** argv)
{
	path dir = string(argc > 1 ? argv[1] : ".");
	TraverseDir(dir);
	return 0;
}
<<KEEP
