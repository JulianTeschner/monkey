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
            lexer.ch = 0;
        } else {
            lexer.ch = lexer.input[lexer.readPosition];
        }
        lexer.position = lexer.readPosition;
        lexer.readPosition += 1;
    }

    pub fn nextToken(self: *Self) token.Token {
        const parsedToken = self.resolveNextToken();
        return parsedToken;
    }

    fn resolveNextToken(self: *Self) token.Token {
        var tok: token.Token = undefined;
        if (self.charIs('=')) {
            tok = token.Token.assign;
        } else if (self.charIs(';')) {
            tok = token.Token.semicolon;
        } else if (self.charIs('(')) {
            tok = token.Token.lparen;
        } else if (self.charIs(')')) {
            tok = token.Token.rparen;
        } else if (self.charIs(',')) {
            tok = token.Token.comma;
        } else if (self.charIs('+')) {
            tok = token.Token.plus;
        } else if (self.charIs('{')) {
            tok = token.Token.lbrace;
        } else if (self.charIs('}')) {
            tok = token.Token.rbrace;
        } else {
            tok = token.Token.eof;
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
};

test "Init lexer" {
    const l = Lexer.init("123");
    try std.testing.expectEqual("123", l.input);
    try std.testing.expectEqual(3, l.input.len);
    const tok = token.Token.eof;
    _ = tok;
}

test "TestNextToken" {
    const input = "=+(){},;";

    const Expected = struct {
        expectedToken: token.Token,
    };

    const tests: []const Expected = &.{
        Expected{ .expectedToken = token.Token.assign },
        Expected{ .expectedToken = token.Token.plus },
        Expected{ .expectedToken = token.Token.lparen },
        Expected{ .expectedToken = token.Token.rparen },
        Expected{ .expectedToken = token.Token.lbrace },
        Expected{ .expectedToken = token.Token.rbrace },
        Expected{ .expectedToken = token.Token.comma },
        Expected{ .expectedToken = token.Token.semicolon },
        Expected{ .expectedToken = token.Token.eof },
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
