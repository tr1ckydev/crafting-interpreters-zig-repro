const std = @import("std");
const Scanner = @import("scanner.zig").Scanner;
const Expr = @import("ast.zig");
const Token = @import("token.zig");
const Interpreter = @import("interpreter.zig").Interpreter;
const Parser = @import("parser.zig").Parser;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    while (true) {
        std.debug.print("> ", .{});
        var buffer: [100]u8 = undefined;
        const input = try std.io.getStdIn().reader().readUntilDelimiter(&buffer, '\n');
        var scanner = Scanner.init(input, std.heap.page_allocator);
        defer scanner.deinit();
        const tokens = try scanner.scanTokens();
        var p = Parser{
            .tokens = tokens,
            .arena = arena.allocator(),
        };
        const stmts = try p.parse();
        //std.debug.print("{any}\n", .{expr.unary.right});
        _ = arena.reset(.retain_capacity);
        var i = Interpreter{};
        i.interpret(stmts);
    }
}
