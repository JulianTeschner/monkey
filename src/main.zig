const std = @import("std");
const token = @import("./lexer/token.zig");
const lexer = @import("./lexer/lexer.zig");

const PROMPT = ">> ";

fn start(writer: std.fs.File.Writer, reader: std.fs.File.Reader) !void {
    var buffer: [65536]u8 = undefined;
    @memset(buffer[0..], 0);
    while (try reader.readUntilDelimiterOrEof(buffer[0..], '\n')) |line| {
        try writer.print("{s}", .{PROMPT});
        if (std.mem.eql(u8, line, "exit")) {
            break;
        }
        var lex = lexer.Lexer.init(line);
        var tok = lex.nextToken();
        while (tok != token.Token.eof) : (tok = lex.nextToken()) {
            _ = try writer.print("{}\n", .{tok});
        }
    }
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    _ = try stdout.write("This is the monkey programming language! \nFeel free to type in commands. \n>> ");
    try start(stdout, stdin);
}
