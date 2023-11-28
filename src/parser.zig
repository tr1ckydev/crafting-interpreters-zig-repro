const Token = @import("token.zig");
const Expr = @import("ast.zig");
const Chameleon = @import("chameleon").Chameleon;
const std = @import("std");
const Stmt = @import("stmt.zig");

pub const Parser = struct {
    tokens: []Token.Token,
    current: usize = 0,
    arena: std.mem.Allocator,
    statements: std.ArrayList(*Stmt.Stmt) = undefined,
    pub fn parse(self: *Parser) !*std.ArrayList(*Stmt.Stmt) {
        self.statements = std.ArrayList(*Stmt.Stmt).init(self.arena);
        while (!self.isAtEnd()) {
            try self.statements.append(try self.statement());
        }
        return &self.statements;
    }
    fn statement(self: *Parser) !*Stmt.Stmt {
        if (self.match(&.{.PRINT})) return try self.printStatement();
        return self.expressionStatement();
    }
    fn printStatement(self: *Parser) !*Stmt.Stmt {
        const value = try self.expression();
        self.consume(.SEMICOLON, "expected ';' after statement");
        var s = Stmt.Stmt{ .print = .{ .expr = value } };
        return &s;
    }
    fn expressionStatement(self: *Parser) !*Stmt.Stmt {
        const expr = try self.expression();
        self.consume(.SEMICOLON, "expected ';' after statement");
        var s = Stmt.Stmt{ .expr = .{ .expr = expr } };
        return &s;
    }
    fn expression(self: *Parser) std.mem.Allocator.Error!*Expr.Expr {
        return self.equality();
    }
    fn equality(self: *Parser) !*Expr.Expr {
        var expr = try self.comparison();
        while (self.match(&.{ .BANG_EQUAL, .EQUAL_EQUAL })) {
            const e = try self.arena.create(Expr.Expr);
            e.* = .{ .binary = .{
                .left = expr,
                .op = self.previous(),
                .right = try self.comparison(),
            } };
            expr = e;
        }
        return expr;
    }
    fn comparison(self: *Parser) !*Expr.Expr {
        var expr = try self.term();
        while (self.match(&.{ .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL })) {
            const e = try self.arena.create(Expr.Expr);
            e.* = .{ .binary = .{
                .left = expr,
                .op = self.previous(),
                .right = try self.term(),
            } };
            expr = e;
        }
        return expr;
    }
    fn term(self: *Parser) !*Expr.Expr {
        var expr = try self.factor();
        while (self.match(&.{ .MINUS, .PLUS })) {
            const e = try self.arena.create(Expr.Expr);
            e.* = .{ .binary = .{
                .left = expr,
                .op = self.previous(),
                .right = try self.factor(),
            } };
            expr = e;
        }
        return expr;
    }
    fn factor(self: *Parser) !*Expr.Expr {
        var expr = try self.unary();
        while (self.match(&.{ .SLASH, .STAR })) {
            const e = try self.arena.create(Expr.Expr);
            e.* = .{ .binary = .{
                .left = expr,
                .op = self.previous(),
                .right = try self.unary(),
            } };
            expr = e;
        }
        return expr;
    }
    fn unary(self: *Parser) !*Expr.Expr {
        if (self.match(&.{ .BANG, .MINUS })) {
            const e = try self.arena.create(Expr.Expr);
            e.* = .{ .unary = .{
                .op = self.previous(),
                .right = try self.unary(),
            } };
            return e;
        }
        return self.primary();
    }
    fn primary(self: *Parser) !*Expr.Expr {
        if (self.match(&.{ .TRUE, .FALSE, .NIL })) {
            switch (self.previous().type) {
                .TRUE => {
                    const e = try self.arena.create(Expr.Expr);
                    e.* = .{ .literal = .{ .value = .{ .boolean = true } } };
                    return e;
                },
                .FALSE => {
                    const e = try self.arena.create(Expr.Expr);
                    e.* = .{ .literal = .{ .value = .{ .boolean = false } } };
                    return e;
                },

                //.NIL => return Expr.Literal{ .nil = {} },
                else => unreachable,
            }
        }
        if (self.match(&.{ .NUMBER, .STRING })) {
            switch (self.previous().type) {
                .NUMBER => {
                    const e = try self.arena.create(Expr.Expr);
                    e.* = .{ .literal = .{ .value = .{ .number = self.previous().literal.?.number } } };
                    return e;
                },
                .STRING => {
                    const e = try self.arena.create(Expr.Expr);
                    e.* = .{ .literal = .{ .value = .{ .string = self.previous().literal.?.string } } };
                    return e;
                },
                else => unreachable,
            }
        }
        if (self.match(&.{.LEFT_PAREN})) {
            const expr = try self.expression();
            self.consume(.RIGHT_PAREN, "expected ')' after expression");
            const e = try self.arena.create(Expr.Expr);
            e.* = .{ .grouping = .{ .expr = expr } };
            return e;
        }
        self.throwError("expected expression", .{});
        const e = try self.arena.create(Expr.Expr);
        e.* = .{ .literal = .{ .value = .{ .number = -99999 } } };
        return e;
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
