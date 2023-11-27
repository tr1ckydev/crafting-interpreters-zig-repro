const Expr = @import("ast.zig");
const Token = @import("token.zig");
const std = @import("std");
pub const Interpreter = struct {
    pub fn interpret(self: *const Interpreter, expr: Expr.Expr) void {
        const value = self.evaluate(expr);
        std.debug.print("{!}\n", .{value});
    }
    pub fn visitLiteralExpr(self: *const Interpreter, expr: Expr.Expr) Token.Literal {
        _ = self;
        return expr.literal.value;
    }
    pub fn visitGroupingExpr(self: *const Interpreter, expr: Expr.Expr) Token.Literal {
        return self.evaluate(expr.grouping.expr);
    }
    fn evaluate(self: *const Interpreter, expr: Expr.Expr) Token.Literal {
        return switch (expr) {
            .binary => |b| b.accept(self),
            .grouping => |g| g.accept(self),
            .literal => |l| l.accept(self),
            .unary => |u| u.accept(self),
        };
    }
    pub fn visitUnaryExpr(self: *const Interpreter, expr: Expr.Expr) Token.Literal {
        const right = self.evaluate(expr);
        return switch (expr.unary.op.type) {
            .MINUS => .{ .number = -right.number },
            .BANG => .{ .boolean = self.isTruthy(right) },
            else => unreachable,
        };
    }
    pub fn visitBinaryExpr(self: *const Interpreter, expr: Expr.Expr) Token.Literal {
        const left = self.evaluate(expr.binary.left);
        const right = self.evaluate(expr.binary.right);
        return switch (expr.binary.op.type) {
            .MINUS => .{ .number = left.number - right.number },
            // .PLUS => left.number + right.number,
            // .SLASH => left / right,
            // .STAR => left * right,
            // .GREATER => left > right,
            // .GREATER_EQUAL => left >= right,
            // .LESS => left < right,
            // .LESS_EQUAL => left <= right,
            // .BANG_EQUAL => left != right,
            // .EQUAL_EQUAL => left == right,
            else => unreachable,
        };
    }
    fn assertNumber(self: *const Interpreter, op: Token.Literal) void {
        _ = self;
        switch (op) {
            .number => return,
            else => throwError("must be number"),
        }
    }
    fn throwError(self: *const Interpreter, comptime msg: []const u8) void {
        _ = self;
        const stderr = std.io.getStdErr().writer();
        stderr.print(msg, .{});
    }
    fn isTruthy(self: *const Interpreter, value: Token.Literal) bool {
        _ = self;
        return switch (value) {
            .boolean => value.boolean,
            else => true,
        };
    }
};
