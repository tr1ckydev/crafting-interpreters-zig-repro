const Token = @import("token.zig");
const std = @import("std");
const Interpreter = @import("interpreter.zig").Interpreter;

pub const Expr = union(enum) {
    binary: *const Binary,
    grouping: *const Grouping,
    literal: *const Literal,
    unary: *const Unary,
};

pub const Binary = struct {
    left: Expr,
    op: Token.Token,
    right: Expr,
    pub fn accept(self: *const Binary, visitor: *const Interpreter) Token.Literal {
        return visitor.*.visitBinaryExpr(Expr{ .binary = self });
    }
};

pub const Grouping = struct {
    expr: Expr,
    pub fn accept(self: *const Grouping, visitor: *const Interpreter) Token.Literal {
        return visitor.*.visitGroupingExpr(Expr{ .grouping = self });
    }
};

pub const Literal = struct {
    value: Token.Literal,
    pub fn accept(self: *const Literal, visitor: *const Interpreter) Token.Literal {
        return visitor.*.visitLiteralExpr(Expr{ .literal = self });
    }
};

pub const Unary = struct {
    op: Token.Token,
    right: Expr,
    pub fn accept(self: *const Unary, visitor: *const Interpreter) Token.Literal {
        return visitor.*.visitUnaryExpr(Expr{ .unary = self });
    }
};
