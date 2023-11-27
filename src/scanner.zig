const std = @import("std");
const Chameleon = @import("chameleon").Chameleon;
const Token = @import("token.zig");

pub const Scanner = struct {
    filename: []const u8 = "<anonymous>",
    source: []const u8,
    tokens: std.ArrayList(Token.Token),
    start: usize = 0,
    current: usize = 0,
    line: usize = 1,
    hadError: bool = false,
    pub fn init(source: []const u8, allocator: std.mem.Allocator) Scanner {
        return .{
            .source = source,
            .tokens = std.ArrayList(Token.Token).init(allocator),
        };
    }
    pub fn deinit(self: *Scanner) void {
        self.tokens.deinit();
    }
    pub fn scanTokens(self: *Scanner) ![]Token.Token {
        while (!self.isAtEnd()) : (self.current += 1) {
            self.start = self.current;
            try self.scanToken();
        }
        try self.addToken(.EOF, null);
        return self.tokens.items;
    }
    pub fn scanToken(self: *Scanner) !void {
        switch (self.source[self.current]) {
            ' ', '\t', '\r' => {},
            '\n' => self.line += 1,
            '(' => try self.addToken(.LEFT_PAREN, null),
            ')' => try self.addToken(.RIGHT_PAREN, null),
            '{' => try self.addToken(.LEFT_BRACE, null),
            '}' => try self.addToken(.RIGHT_BRACE, null),
            ',' => try self.addToken(.COMMA, null),
            '.' => try self.addToken(.DOT, null),
            '-' => try self.addToken(.MINUS, null),
            '+' => try self.addToken(.PLUS, null),
            ';' => try self.addToken(.SEMICOLON, null),
            '*' => try self.addToken(.STAR, null),
            '!' => try self.addToken(if (self.match('=')) .BANG_EQUAL else .BANG, null),
            '=' => try self.addToken(if (self.match('=')) .EQUAL_EQUAL else .EQUAL, null),
            '<' => try self.addToken(if (self.match('=')) .LESS_EQUAL else .LESS, null),
            '>' => try self.addToken(if (self.match('=')) .GREATER_EQUAL else .GREATER, null),
            '/' => {
                if (self.match('/')) {
                    while (!self.isAtEnd() and self.source[self.current] != '\n') self.current += 1;
                } else {
                    try self.addToken(.SLASH, null);
                }
            },
            '"' => try self.readString(),
            '0'...'9' => try self.readNumber(),
            'a'...'z', 'A'...'Z', '_' => try self.readIdentifier(),
            else => |c| try self.throwError("unexpected character '{c}'", .{c}),
        }
    }
    fn readString(self: *Scanner) !void {
        self.current += 1;
        const start = self.current;
        while (!self.isAtEnd() and self.source[self.current] != '"') : (self.current += 1) {
            if (self.source[self.current] == '\n') self.line += 1;
        }
        if (self.isAtEnd()) return try self.throwError("unterminated string", .{});
        try self.addToken(.STRING, Token.Literal{ .string = self.source[start..self.current] });
    }
    fn readNumber(self: *Scanner) !void {
        while (!self.isAtEnd() and std.ascii.isDigit(self.source[self.current])) self.current += 1;
        if (!self.isAtEnd() and self.source[self.current] == '.') {
            self.current += 1;
            while (!self.isAtEnd() and std.ascii.isDigit(self.source[self.current])) self.current += 1;
        }
        try self.addToken(.NUMBER, Token.Literal{ .number = try std.fmt.parseFloat(f64, self.source[self.start..self.current]) });
        self.current -= 1;
    }
    fn readIdentifier(self: *Scanner) !void {
        while (!self.isAtEnd() and std.ascii.isAlphanumeric(self.source[self.current])) self.current += 1;
        const keyword = Token.Map.get(self.source[self.start..self.current]);
        try self.addToken(keyword orelse .IDENTIFIER, null);
    }
    fn match(self: *Scanner, expected: u8) bool {
        if (self.current + 1 >= self.source.len) return false;
        if (self.source[self.current + 1] != expected) return false;
        self.current += 1;
        return true;
    }
    fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }
    fn addToken(self: *Scanner, token_type: Token.Type, literal: ?Token.Literal) !void {
        try self.tokens.append(Token.Token{
            .type = token_type,
            //.lexeme = self.source[self.start..self.current],
            .literal = literal,
            .line = self.line,
            .col = self.start,
        });
    }
    fn throwError(self: *Scanner, comptime format: []const u8, args: anytype) !void {
        self.hadError = true;
        comptime var cham = Chameleon.init(.Auto);
        const stderr = std.io.getStdErr().writer();
        try stderr.print(cham.bold().fmt("[{s}:{}:{}] {s} "), .{ self.filename, self.line, self.start, cham.red().fmt("token error:") });
        try stderr.print(cham.bold().fmt(format ++ "\n"), args);
    }
};
