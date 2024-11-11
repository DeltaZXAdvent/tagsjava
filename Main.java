import com.deltazx.wrapper.com.sun.tools.javac.util.Context;
import com.deltazx.wrapper.com.sun.tools.javac.parser.ParserFactory;
import com.deltazx.wrapper.com.sun.tools.javac.parser.Parser;
import com.deltazx.wrapper.com.sun.tools.javac.tree.JCTree.JCCompilationUnit;
import com.deltazx.wrapper.com.sun.tools.javac.tree.TreeMaker;

// let's don't consider visibility, parse the specified .java files and derive all its class hierarchy and member declarations.
// and in emacs get the current symbol's full name using treesitter? a real time parser?
public class Main {
    public static void main (String[] args) {
	Context context = new Context ();
	System.out.println ("Hello World!");
	if (true) return;
        // ParserFactory parserFactory = ParserFactory.instance(context);
	// TreeMaker make = TreeMaker.instance (context);
	// CharSequence content = null;
        // JCCompilationUnit tree = make.TopLevel(List.nil());
	// Parser parser = parserFactory.newParser(content, true, true,
	// 					true, true);
	// tree = parser.parseCompilationUnit();
    }
}
