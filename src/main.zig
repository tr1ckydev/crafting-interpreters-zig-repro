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
        // for (tokens) |token| {
        //     std.debug.print("{}\n", .{token});
        // }
        var p = Parser{
            .tokens = tokens,
            .arena = arena.allocator(),
        };
        const expr = p.parse();
        std.debug.print("{any}\n", .{expr});
        _ = arena.reset(.retain_capacity);
        // var i = Interpreter{};
        // i.interpret(expr);
    }
    // const expr = Expr.Expr{ .binary = &.{
    //     .left = &.{ .literal = &.{ .value = .{ .number = 10 } } },
    //     .op = .{ .type = .MINUS, .literal = null, .line = 1, .col = 1 },
    //     .right = &.{ .literal = &.{ .value = .{ .number = 7 } } },
    // } };
    // var i = Interpreter{};
    // i.interpret(&expr);
}
