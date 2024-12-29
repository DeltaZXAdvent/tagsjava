# tagsjava
This is a project aiming to provide Java parser for Emacs with hacking javac.
The java toolchain gives little help of using jdk source code.
Because the naming is duplicated and you have to rename all the packages and declarations to use the source code.
So I tried using command line tools and some scheme scripts.
But this is very troublesome and now I haven't made it but I assume it possible.

I regard the java language as not modular, because refactoring is hard by hand.
There are eclipse and open source IDE Java parsers and there is a project called JavaParser in Java.
But somewhat because I want an efficient one and a possibly real-time one so I tried the challenge.

After hacking javac, I need to hack the emacs symbol finding system. 
Because it obviously lacks some contextual functionalities.

And most of the code you see in the repo is experimental and obsolete.

And this project is mainly a tool for the grand-minecraft project. 
Because I want to write Java with "Free Software".

# <2024-12-27 Fri 21:06>
Holy shit, I guess this is impossible...
If not unloading or preventing loading of the default modules, other modules which depend on these modules cannot be changed into different packages for the existence of sealed classes.
# <2024-12-29 Sun 13:00>
For example, sealed interface ~java.lang.foreign.MemorySegment~ permits ~jdk.internal.foreign.AbstractMemorySegment.Impl~. The former is a preview API while the latter is not. So it is hard to reuse the code unless you compile another whole copy of OpenJDK which runs on JVM.
But eventually I did manage to reduce the compilation errors to 54.

# Rethoughts
Maybe Java's symbol finding shouldn't be based on text-searching rather than on reflection on loaded classes? But how do you go to source files then? Maybe it has provided debugging information? Yes ~javac~ ~-g~ provides this.
## Rethought on the refactoring ability i.e. high-level degree / expressive power of Java
Not bad if you have a parser, regular expression will probably work also. But it is hard to use the private functionalities supposedly, especially for those already in the basic modules.

# I give up using Emacs this time. It is also not necessary to do so.
