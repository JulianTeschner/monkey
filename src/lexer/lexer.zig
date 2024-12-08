const std = @import("std");
const token = @import("token.zig");

pub const Lexer = struct {
    input: []const u8,
    position: usize,
    readPosition: usize,
    ch: ?u8,

    const Self = @This();

    fn init(input: [:0]const u8) Lexer {
        var lexer = Lexer{ .input = input, .position = 0, .readPosition = 0, .ch = null };
        lexer.readChar();

        return lexer;
    }

    fn readChar(lexer: *Lexer) void {
        if (lexer.readPosition >= lexer.input.len) {
            lexer.ch = null;
        } else {
            lexer.ch = lexer.input[lexer.readPosition];
        }
        lexer.position = lexer.readPosition;
        lexer.readPosition += 1;
    }

    fn peekChar(lexer: *Lexer) ?u8 {
        if (lexer.readPosition >= lexer.input.len) {
            return null;
        } else {
            return lexer.input[lexer.readPosition];
        }
    }

    pub fn nextToken(self: *Self) token.Token {
        const parsedToken = self.resolveNextToken();
        return parsedToken;
    }

    fn resolveNextToken(self: *Self) token.Token {
        var tok: token.Token = undefined;
        self.skipWhitespace();
        if (self.charIs('=')) {
            if (self.peekCharIs('=')) {
                tok = .equal;
                self.readChar();
            } else {
                tok = .assign;
            }
        } else if (self.charIs('+')) {
            tok = .plus;
        } else if (self.charIs('-')) {
            tok = .minus;
        } else if (self.charIs('!')) {
            if (self.peekCharIs('=')) {
                tok = .notEqual;
                self.readChar();
            } else {
                tok = .bang;
            }
        } else if (self.charIs('/')) {
            tok = .slash;
        } else if (self.charIs('*')) {
            tok = .asterisk;
        } else if (self.charIs('<')) {
            tok = .lt;
        } else if (self.charIs('>')) {
            tok = .gt;
        } else if (self.charIs(';')) {
            tok = .semicolon;
        } else if (self.charIs('(')) {
            tok = .lparen;
        } else if (self.charIs(')')) {
            tok = .rparen;
        } else if (self.charIs(',')) {
            tok = .comma;
        } else if (self.charIs('+')) {
            tok = .plus;
        } else if (self.charIs('{')) {
            tok = .lbrace;
        } else if (self.charIs('}')) {
            tok = .rbrace;
        } else {
            if (self.ch) |char| {
                if (isLetter(char)) {
                    const ident = self.readIdentifier();
                    tok = lookupIdent(ident);
                    return tok;
                } else if (isDigit(char)) {
                    const number = self.readNumber();
                    tok = .{ .int = number };
                    return tok;
                } else {
                    tok = .{ .illegal = char };
                }
            } else {
                tok = .eof;
            }
        }
        self.readChar();
        return tok;
    }

    fn charIs(self: *Self, expected: u8) bool {
        if (self.ch) |ch| {
            return ch == expected;
        } else {
            return false;
        }
    }
    fn peekCharIs(self: *Self, expected: u8) bool {
        if (self.peekChar()) |ch| {
            return ch == expected;
        } else {
            return false;
        }
    }

    fn readIdentifier(self: *Self) []const u8 {
        const position = self.position;
        while (isLetter(self.ch.?)) {
            self.readChar();
        }
        return self.input[position..self.position];
    }

    fn readNumber(self: *Self) []const u8 {
        const position = self.position;
        while (isDigit(self.ch.?)) {
            self.readChar();
        }
        return self.input[position..self.position];
    }

    fn isLetter(ch: u8) bool {
        return 'a' <= ch and ch <= 'z' or 'A' <= ch and ch <= 'Z' or ch == '_';
    }
    fn isDigit(ch: u8) bool {
        return '0' <= ch and ch <= '9';
    }

    fn lookupIdent(ident: []const u8) token.Token {
        if (std.mem.eql(u8, ident, "fn")) {
            return token.Token.function;
        } else if (std.mem.eql(u8, ident, "let")) {
            return token.Token.let;
        } else if (std.mem.eql(u8, ident, "true")) {
            return token.Token.true_;
        } else if (std.mem.eql(u8, ident, "false")) {
            return token.Token.false_;
        } else if (std.mem.eql(u8, ident, "if")) {
            return token.Token.if_;
        } else if (std.mem.eql(u8, ident, "else")) {
            return token.Token.else_;
        } else if (std.mem.eql(u8, ident, "return")) {
            return token.Token.return_;
        } else if (std.mem.eql(u8, ident, "macro")) {
            return token.Token.macro;
        } else {
            return token.Token{ .ident = ident };
        }
    }

    fn skipWhitespace(self: *Self) void {
        while (self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r') {
            self.readChar();
        }
    }
};

test "Init lexer" {
    const l = Lexer.init("123");
    try std.testing.expectEqual("123", l.input);
    try std.testing.expectEqual(3, l.input.len);
    const tok = token.Token.eof;
    _ = tok;
}

test "TestNextToken" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x,y) {
        \\  x + y;
        \\};
        \\
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\
        \\if (5 < 10) {
        \\  return true;
        \\} else {
        \\  return false;
        \\}
        \\
        \\10 == 10;
        \\10 != 9;
    ;
    std.debug.print("{s}\n", .{input});

    const Expected = struct {
        expectedToken: token.Token,
    };

    const tests: []const Expected = &.{
        Expected{ .expectedToken = .let },
        Expected{ .expectedToken = .{ .ident = "five" } },
        Expected{ .expectedToken = .assign },
        Expected{ .expectedToken = .{ .int = "5" } },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .let },
        Expected{ .expectedToken = .{ .ident = "ten" } },
        Expected{ .expectedToken = .assign },
        Expected{ .expectedToken = .{ .int = "10" } },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .let },
        Expected{ .expectedToken = .{ .ident = "add" } },
        Expected{ .expectedToken = .assign },
        Expected{ .expectedToken = .function },

        Expected{ .expectedToken = .lparen },
        Expected{ .expectedToken = .{ .ident = "x" } },
        Expected{ .expectedToken = .comma },
        Expected{ .expectedToken = .{ .ident = "y" } },
        Expected{ .expectedToken = .rparen },
        Expected{ .expectedToken = .lbrace },
        Expected{ .expectedToken = .{ .ident = "x" } },
        Expected{ .expectedToken = .plus },
        Expected{ .expectedToken = .{ .ident = "y" } },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .rbrace },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .let },
        Expected{ .expectedToken = .{ .ident = "result" } },
        Expected{ .expectedToken = .assign },
        Expected{ .expectedToken = .{ .ident = "add" } },
        Expected{ .expectedToken = .lparen },
        Expected{ .expectedToken = .{ .ident = "five" } },
        Expected{ .expectedToken = .comma },
        Expected{ .expectedToken = .{ .ident = "ten" } },
        Expected{ .expectedToken = .rparen },
        Expected{ .expectedToken = .semicolon },

        Expected{ .expectedToken = .bang },
        Expected{ .expectedToken = .minus },
        Expected{ .expectedToken = .slash },
        Expected{ .expectedToken = .asterisk },
        Expected{ .expectedToken = .{ .int = "5" } },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .{ .int = "5" } },
        Expected{ .expectedToken = .lt },
        Expected{ .expectedToken = .{ .int = "10" } },
        Expected{ .expectedToken = .gt },
        Expected{ .expectedToken = .{ .int = "5" } },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .if_ },
        Expected{ .expectedToken = .lparen },
        Expected{ .expectedToken = .{ .int = "5" } },
        Expected{ .expectedToken = .lt },
        Expected{ .expectedToken = .{ .int = "10" } },
        Expected{ .expectedToken = .rparen },
        Expected{ .expectedToken = .lbrace },
        Expected{ .expectedToken = .return_ },
        Expected{ .expectedToken = .true_ },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .rbrace },
        Expected{ .expectedToken = .else_ },
        Expected{ .expectedToken = .lbrace },
        Expected{ .expectedToken = .return_ },
        Expected{ .expectedToken = .false_ },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .rbrace },
        Expected{ .expectedToken = .{ .int = "10" } },
        Expected{ .expectedToken = .equal },
        Expected{ .expectedToken = .{ .int = "10" } },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .{ .int = "10" } },
        Expected{ .expectedToken = .notEqual },
        Expected{ .expectedToken = .{ .int = "9" } },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .eof },
    };

    var lex = Lexer.init(input);

    for (tests, 0..tests.len) |tt, i| {
        const tok: token.Token = lex.nextToken();

        std.testing.expectEqualDeep(tt.expectedToken, tok) catch {
            std.debug.print("test {d} - tokentype wrong. expected={}, got={}\n", .{
                i, tt.expectedToken, tok,
            });
        };
    }
}
