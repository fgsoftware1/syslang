module test;

import std::io;

extern fn int add_one(int x);

fn int main()
{
    int result = add_one(5);
    io::printfn("add_one(5) = %d", result);
    return result;
}
