module syslang;

import std::io;
import std::collections::list;

fn String codegen_fn_function(FnFunction func)
{
	DString output;
	output.append("    .global ");
	output.append(func.name);
	output.append("\n");
	output.append(func.name);
	output.append(":\n");
	output.append("    push %rbp\n");
	output.append("    mov %rsp, %rbp\n");

	foreach (stmt : func.body)
	{
		output.append(codegen_fn_statement(stmt));
	}

	output.append("    pop %rbp\n");
	output.append("    ret\n");
	return output.str_view();
}

fn String codegen_fn_statement(FnStatement stmt)
{
	DString output;
	switch (stmt.kind)
	{
		case FnStatementKind.FN_STMT_RETURN:
			output.append("    call ");
			output.append(stmt.value);
			output.append("\n");
		default:
			io::printfn("Unknown fn statement");
	}
	return output.str_view();
}

fn String codegen_asm_function(AsmFunction func)
{
	DString output;
	if (func.is_public)
	{
		output.append("    .global ");
		output.append(func.name);
		output.append("\n");
	}
	output.append(func.name);
	output.append(":\n");
	output.append("    push %rbp\n");
	output.append("    mov %rsp, %rbp\n");

	foreach (stmt : func.body)
	{
		output.append(codegen_opcode(stmt));
	}

	output.append("    pop %rbp\n");
	output.append("    ret\n");
	return output.str_view();
}

fn String codegen_opcode(Statement stmt)
{
	DString output;
	switch (stmt.name)
	{
		case "mov":
			output.append("    mov ");
			output.append(codegen_operand(stmt.args[0]));
			output.append(", ");
			output.append(codegen_operand(stmt.args[1]));
			output.append("\n");
		case "add":
			output.append("    add ");
			output.append(codegen_operand(stmt.args[0]));
			output.append(", ");
			output.append(codegen_operand(stmt.args[1]));
			output.append("\n");
		case "syscall":
			output.append("    syscall\n");
		default:
			io::printfn("Unknown opcode: %s", stmt.name);
	}
	return output.str_view();
}

fn String codegen_operand(Operand op)
{
	if (op.kind == OperandKind.OPERAND_REGISTER)
	{
		DString output;
		output.append("%");
		output.append(op.reg);
		return output.str_view();
	}
	else
	{
		return string::format(tmem, "$%d", op.imm);
	}
}

fn String codegen_function(Function func)
{
	switch (func.kind)
	{
		case FunctionKind.FUNC_ASM:
			return codegen_asm_function(func.asm_fn);
		case FunctionKind.FUNC_FN:
			return codegen_fn_function(func.fn_fn);
	}
}

fn String codegen_module(List{Function} funcs)
{
	DString output;
	output.append("    .text\n");
	foreach (func : funcs)
	{
		output.append(codegen_function(func));
		output.append("\n");
	}
	return output.str_view();
}
