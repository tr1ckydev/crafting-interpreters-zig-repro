const Token = @import("token.zig");
const Expr = @import("ast.zig");
const Chameleon = @import("chameleon").Chameleon;
const std = @import("std");

pub const Parser = struct {
    tokens: []Token.Token,
    current: usize = 0,
    pub fn parse(self: *Parser) Expr.Expr {
        return self.expression();
    }
    fn expression(self: *Parser) Expr.Expr {
        return self.equality();
    }
    fn equality(self: *Parser) Expr.Expr {
        var expr = self.comparison();
        while (self.match(&.{ .BANG_EQUAL, .EQUAL_EQUAL })) {
            expr = .{ .binary = &.{
                .left = expr,
                .op = self.previous(),
                .right = self.comparison(),
            } };
        }
        return expr;
    }
    fn comparison(self: *Parser) Expr.Expr {
        var expr = self.term();
        while (self.match(&.{ .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL })) {
            expr = .{ .binary = &.{
                .left = expr,
                .op = self.previous(),
                .right = self.term(),
            } };
        }
        return expr;
    }
    fn term(self: *Parser) Expr.Expr {
        var expr = self.factor();
        while (self.match(&.{ .MINUS, .PLUS })) {
            expr = .{ .binary = &.{
                .left = expr,
                .op = self.previous(),
                .right = self.factor(),
            } };
        }
        return expr;
    }
    fn factor(self: *Parser) Expr.Expr {
        var expr = self.unary();
        while (self.match(&.{ .SLASH, .STAR })) {
            expr = .{ .binary = &.{
                .left = expr,
                .op = self.previous(),
                .right = self.unary(),
            } };
        }
        return expr;
    }
    fn unary(self: *Parser) Expr.Expr {
        if (self.match(&.{ .BANG, .MINUS })) {
            return .{ .unary = &.{
                .op = self.previous(),
                .right = self.unary(),
            } };
        }
        return self.primary();
    }
    fn primary(self: *Parser) Expr.Expr {
        if (self.match(&.{ .TRUE, .FALSE, .NIL })) {
            switch (self.previous().type) {
                .TRUE => return .{ .literal = &.{ .value = .{ .boolean = true } } },
                .FALSE => return .{ .literal = &.{ .value = .{ .boolean = false } } },
                //.NIL => return Expr.Literal{ .nil = {} },
                else => unreachable,
            }
        }
        if (self.match(&.{ .NUMBER, .STRING })) {
            switch (self.previous().type) {
                .NUMBER => {
                    return .{ .literal = &.{ .value = .{ .number = self.previous().literal.?.number } } };
                },
                .STRING => return .{ .literal = &.{ .value = .{ .string = self.previous().literal.?.string } } },
                else => unreachable,
            }
        }
        if (self.match(&.{.LEFT_PAREN})) {
            const expr = self.expression();
            self.consume(.RIGHT_PAREN, "expected ')' after expression");
            return .{ .grouping = &.{ .expr = expr } };
        }
        self.throwError("expected expression", .{});
        return .{ .literal = &.{ .value = .{ .number = -99999 } } };
    }
    fn consume(self: *Parser, token_type: Token.Type, comptime message: []const u8) void {
        if (self.tokens[self.current].type == token_type) {
            self.current += 1;
            return;
        }
        self.throwError(message, .{});
    }
    fn synchronize(self: *Parser) void {
        self.current += 1;
        while (!self.isAtEnd()) {
            if (self.previous().type == .SEMICOLON) return;
            switch (self.tokens[self.current].type) {
                .CLASS, .FUN, .VAR, .FOR, .IF, .WHILE, .PRINT, .RETURN => return,
                else => self.current += 1,
            }
        }
    }
    fn match(self: *Parser, types: []const Token.Type) bool {
        for (types) |t| {
            if (self.tokens[self.current].type == t) {
                self.current += 1;
                return true;
            }
        }
        return false;
    }
    fn previous(self: *Parser) Token.Token {
        return self.tokens[self.current - 1];
    }
    fn isAtEnd(self: *Parser) bool {
        return self.tokens[self.current].type == .EOF;
    }
    fn throwError(self: *Parser, comptime format: []const u8, args: anytype) void {
        const token = self.tokens[self.current];
        comptime var cham = Chameleon.init(.Auto);
        const stderr = std.io.getStdErr().writer();
        stderr.print(cham.bold().fmt("[{}:{}] {s} "), .{ token.line, token.col, cham.red().fmt("parse error:") }) catch unreachable;
        stderr.print(cham.bold().fmt(format ++ "\n"), args) catch unreachable;
    }
};
