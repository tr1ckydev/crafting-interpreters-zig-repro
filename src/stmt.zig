const std = @import("std");
const AstExpr = @import("ast.zig").Expr;
const Interpreter = @import("interpreter.zig").Interpreter;

pub const Stmt = union(enum) {
    expr: Expr,
    print: Print,
};

pub const Print = struct {
    expr: *AstExpr,
    pub fn accept(self: Print, visitor: *Interpreter) void {
        return visitor.*.visitPrintStmt(&.{ .print = self });
    }
};

pub const Expr = struct {
    expr: *AstExpr,
    pub fn accept(self: Expr, visitor: *Interpreter) void {
        return visitor.*.visitExprStmt(&.{ .expr = self });
    }
};
