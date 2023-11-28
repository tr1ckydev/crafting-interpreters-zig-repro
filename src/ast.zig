const Token = @import("token.zig");
const std = @import("std");
const Interpreter = @import("interpreter.zig").Interpreter;

pub const Expr = union(enum) {
    binary: Binary,
    grouping: Grouping,
    literal: Literal,
    unary: Unary,
};

pub const Binary = struct {
    left: *Expr,
    op: Token.Token,
    right: *Expr,
    pub fn accept(self: Binary, visitor: *Interpreter) Token.Literal {
        return visitor.*.visitBinaryExpr(&.{ .binary = self });
    }
};

pub const Grouping = struct {
    expr: *Expr,
    pub fn accept(self: Grouping, visitor: *Interpreter) Token.Literal {
        return visitor.*.visitGroupingExpr(&.{ .grouping = self });
    }
};

pub const Literal = struct {
    value: Token.Literal,
    pub fn accept(self: Literal, visitor: *Interpreter) Token.Literal {
        return visitor.*.visitLiteralExpr(&.{ .literal = self });
    }
};

pub const Unary = struct {
    op: Token.Token,
    right: *Expr,
    pub fn accept(self: Unary, visitor: *Interpreter) Token.Literal {
        return visitor.*.visitUnaryExpr(&.{ .unary = self });
    }
};
