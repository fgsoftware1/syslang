module syslang;

import std::io;
import std::io::file;
import std::collections::list;

fn int main(String[] args)
{
	if (args.len < 2)
	{
		io::printn("Usage: syslang <source_file> [output_file]");
		return 1;
	}

	String filename = args[1];
	String out_filename = args.len >= 3 ? args[2] : "output.s";

	File file = file::open(filename, "r")!!;
	char[] content = io::read_fully(tmem, &file)!!;
	(void)file.close();

	Lexer lexer = newLexer((String)content);
	List{Token} tokens = lexer.tokenize();

	Parser parser = newParser(tokens);
	List{Function} funcs = parser.parseModule();

	String output_asm = codegen_module(funcs);

	File out = file::open(out_filename, "w")!!;
	out.write((char[])output_asm)!!;
	(void)out.close();

	io::printfn("Wrote assembly to %s", out_filename);

	return 0;
}
