const Expr = @import("ast.zig");
const Token = @import("token.zig");
const std = @import("std");
const Stmt = @import("stmt.zig");

pub const Interpreter = struct {
    pub fn interpret(self: *Interpreter, stmts: *const std.ArrayList(*Stmt.Stmt)) void {
        for (stmts.*.items) |stmt| {
            self.execute(stmt);
        }
    }
    fn execute(self: *Interpreter, stmt: *Stmt.Stmt) void {
        switch (stmt.*) {
            .expr => |e| e.accept(self),
            .print => |p| p.accept(self),
        }
    }
    pub fn visitLiteralExpr(self: *Interpreter, expr: *const Expr.Expr) Token.Literal {
        _ = self;
        return expr.literal.value;
    }
    pub fn visitGroupingExpr(self: *Interpreter, expr: *const Expr.Expr) Token.Literal {
        return self.evaluate(expr.grouping.expr);
    }
    fn evaluate(self: *Interpreter, expr: *const Expr.Expr) Token.Literal {
        return switch (expr.*) {
            .binary => |b| b.accept(self),
            .grouping => |g| g.accept(self),
            .literal => |l| l.accept(self),
            .unary => |u| u.accept(self),
        };
    }
    pub fn visitUnaryExpr(self: *Interpreter, expr: *const Expr.Expr) Token.Literal {
        const right = self.evaluate(expr.*.unary.right);
        return switch (expr.*.unary.op.type) {
            .MINUS => .{ .number = -right.number },
            .BANG => .{ .boolean = !self.toBoolean(right) },
            else => unreachable,
        };
    }
    pub fn visitBinaryExpr(self: *Interpreter, expr: *const Expr.Expr) Token.Literal {
        const left = self.evaluate(expr.*.binary.left);
        const right = self.evaluate(expr.*.binary.right);
        return switch (expr.*.binary.op.type) {
            .MINUS => .{ .number = left.number - right.number },
            .PLUS => .{ .number = left.number + right.number },
            .SLASH => .{ .number = left.number / right.number },
            .STAR => .{ .number = left.number * right.number },
            .GREATER => .{ .boolean = left.number > right.number },
            .GREATER_EQUAL => .{ .boolean = left.number >= right.number },
            .LESS => .{ .boolean = left.number < right.number },
            .LESS_EQUAL => .{ .boolean = left.number <= right.number },
            .BANG_EQUAL => .{ .boolean = left.number != right.number },
            .EQUAL_EQUAL => .{ .boolean = left.number == right.number },
            else => unreachable,
        };
    }
    fn assertNumber(self: *Interpreter, op: Token.Literal) void {
        _ = self;
        switch (op) {
            .number => return,
            else => throwError("must be number"),
        }
    }
    pub fn visitExprStmt(self: *Interpreter, stmt: *const Stmt.Stmt) void {
        _ = self.evaluate(stmt.*.expr.expr);
    }
    pub fn visitPrintStmt(self: *Interpreter, stmt: *const Stmt.Stmt) void {
        const value = self.evaluate(stmt.*.print.expr);
        std.debug.print("{}", .{value});
    }
    fn throwError(self: *Interpreter, comptime msg: []const u8) void {
        _ = self;
        const stderr = std.io.getStdErr().writer();
        stderr.print(msg, .{});
    }
    fn toBoolean(self: *Interpreter, value: Token.Literal) bool {
        _ = self;
        return switch (value) {
            .boolean => value.boolean,
            else => true,
        };
    }
};
