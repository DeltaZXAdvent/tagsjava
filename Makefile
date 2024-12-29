.PHONY: clean-jdk-classes									\
	generate-jdk-classes									\
	api-packages-dotted.list									\
	non-api-packages.list									\
	Main.java
clean-jdk-classes:
	echo do it yourself
generate-jdk-classes:
	echo TODO
# I choose to generate wrappers for the needed packages while not all.
generate-wrapper-for-non-api-packages:
	cat non-api-packages.list								\
	| awk '											\
BEGIN { FS = "/" }										\
{												\
	dir	       = substr ($$0, length ($$1 $$2) + 3, length ());				\
	module_dir = $$1 "/" $$2 "/";								\
	system ("mkdir -p " module_dir "com/deltazx/");						\
	system ("ln -s ../../ "module_dir"com/deltazx/wrapper");				\
}												\
'
# delete-wrapper:
# 	rm -i `find openjdk21-src/ -type l`
generate-wrapper-for-all-packages:
	for m in `ls -d openjdk21-src/*/`; do \
		mkdir -p $$m/com/deltazx/;\
		ln -s ../../ $$m/com/deltazx/wrapper;\
	done
modify-package-decls-of-classes: classfiles.list
	for f in `cat classfiles.list`; do\
		echo $${f::-6}.java; \
		sed -i '/^package/,//s/^package /package com.deltazx.wrapper./' $${f::-6}.java;\
	done
modify-package-decls-of-packages: packages.list
	for p in `cat packages.list`; do\
		dir=`find openjdk21-src/ -type d -wholename "openjdk21-src/*/$$p"`;\
		echo $$dir;\
		break;\
		for f in `find $$dir -wholename "*.java"`; do\
			sed -i '/^package/,//s/^package /package com.deltazx.wrapper./' $$f;\
		done;\
	done
modify-package-decls-of-all: api-packages.list #let's first try to modify imports and package decls
	for f in `find openjdk21-src/* -type d`; do	\
		echo TODO;				\
	done
# delete-api-packges:
# 	for p in `cat api-packages.list`; do \
# 		echo Package: $$p; \
# 		rm -IR $$p; \
# 	done
delete-api-packges-once:
	cat api-packages.list; \
	rm -IR `cat api-packages.list | grep -F -v -f non-api-packages.list api-packages.list`
delete-api-classes:
	echo TODO
# Maybe jdeps is enough (no?)
non-api-packages.list: api-packages.list
	cat classes.list | awk '								\
BEGIN { FS = "/"; RS = "-C " }									\
{												\
	if ($$0 != "") {									\
		third  = length ($$1 $$2) + 3;							\
		total  = length () - length ($$NF);						\
		print $$1 "/" $$2 "/" substr ($$0, third + 1, total - third)			\
	}											\
}												\
'												\
	| sort -u										\
	| grep --fixed-strings --line-regexp --file=api-packages.list > non-api-packages.list
all-packages.list: all-module-packages.list
	cat all-module-packages.list | awk	\
'						\
{ print $$2 }					\
'						\
	| sort -u				\
	> all-packages.list
classes.list: classfiles.list		#printf "%s", ... could be replaced by print and ORS
	cat classfiles.list \
	|awk						\
'												\
BEGIN { FS = "/"; module = "" }									\
{												\
	if ($$2 != module) {									\
		module = $$2;									\
	}											\
	printf "%s", "-C openjdk21-src/" module "/" " ";					\
	printf "%s", substr ($$0, length ($$1 FS module FS) + 1) " "				\
}												\
'												\
	>classes.list
classfiles.list:
	find openjdk21-src/ -name "*.class" > classfiles.list
api-packages-dotted.list:
	echo "for (Module module: ModuleLayer.boot ().modules ())				\
	for (String pn: module.getPackages ())							\
	if (module.isExported (pn)) System.out.println (module.getName () + \" \" + pn);"	\
	| jshell --feedback silent > api-packages-dotted.list
all-module-packages.list:
	echo "for (Module module: ModuleLayer.boot ().modules ())				\
	for (String pn: module.getPackages ())							\
	System.out.println (module.getName () + \" \" + pn);"	\
	| jshell --feedback silent > all-module-packages.list
api-packages-paths-for-scheme.list: api-packages-dotted.list
	cat api-packages-dotted.list \
	| awk '{ print $$1 "/" gensub (/\./, "/", "g", $$2) }' > api-packages-paths-for-scheme.list
api-packages.list: api-packages-dotted.list
	cat api-packages-dotted.list \
	| awk '{ print "openjdk21-src/" $$1 "/" gensub (/\./, "/", "g", $$2) }'>api-packages.list
compile-verbose: Main.java
	javac -verbose -Xprefer:source --class-path `ls -d openjdk21-src/*/ | awk 'BEGIN { ORS = ":" } { print $$0 } END { printf "%s", "." }'` Main.java
compile: Main.java
	javac --enable-preview --release 21 -Xprefer:source --source-path `ls -d openjdk21-src/*/ | awk 'BEGIN { ORS = ":" } { print $$0 } END { printf "%s", "." }'` Main.java
generate-openjdk-src:
	if [ -d openjdk21-src ]; then\
		gio trash openjdk21-src || exit;\
	fi;\
	unzip /usr/lib/jvm/java-21-openjdk/lib/src.zip -d openjdk21-src
test:
	echo begin;\
	exit;\
	echo end;
disable-module-infos:
	for f in `find openjdk21-src/ -name "module-info.java"`; do\
		echo $$f; \
		mv $$f $${f::-16}-module-info.java; \
	done
