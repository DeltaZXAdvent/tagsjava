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
