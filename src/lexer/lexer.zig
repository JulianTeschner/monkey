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
    const input =
        \\ let five = 5;
        \\ let ten = 10;
        \\ let add = fn(x,y) {
        \\  x + y;
        \\ };
        \\
        \\ let result = add(five, ten);
    ;
    std.debug.print("{s}\n", .{input});

    const Expected = struct {
        expectedToken: token.Token,
    };
    const a: token.Token = .{ .ident = "abc" };
    std.debug.print("{}\n", .{a});

    const tests: []const Expected = &.{
        Expected{ .expectedToken = .let },
        Expected{ .expectedToken = .{ .ident = "five" } },
        Expected{ .expectedToken = .assign },
        Expected{ .expectedToken = .{ .int = 5 } },
        Expected{ .expectedToken = .semicolon },
        Expected{ .expectedToken = .let },
        Expected{ .expectedToken = .{ .ident = "ten" } },
        Expected{ .expectedToken = .assign },
        Expected{ .expectedToken = .{ .int = 10 } },
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
