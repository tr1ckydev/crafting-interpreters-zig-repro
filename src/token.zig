const std = @import("std");
pub const Type = enum {
    // Single-character tokens.
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,

    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FUN,
    FOR,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    EOF,
};

pub const Literal = union(enum) {
    string: []const u8,
    number: f64,
    boolean: bool,
    pub fn toString(self: *Literal, allocator: std.mem.Allocator) ![]const u8 {
        return switch (self) {
            .string => |s| try std.fmt.allocPrint(allocator, "{s}", .{s}),
            else => |d| try std.fmt.allocPrint(allocator, "{}", .{d}),
        };
    }
};

pub const Token = struct {
    type: Type,
    //lexeme: []const u8,
    literal: ?Literal,
    line: usize,
    col: usize,
};

pub const Map = @import("std").ComptimeStringMap(Type, .{
    .{ "and", .AND },
    .{ "class", .CLASS },
    .{ "else", .ELSE },
    .{ "false", .FALSE },
    .{ "fun", .FUN },
    .{ "for", .FOR },
    .{ "if", .IF },
    .{ "nil", .NIL },
    .{ "or", .OR },
    .{ "print", .PRINT },
    .{ "return", .RETURN },
    .{ "super", .SUPER },
    .{ "this", .THIS },
    .{ "true", .TRUE },
    .{ "var", .VAR },
    .{ "while", .WHILE },
});
