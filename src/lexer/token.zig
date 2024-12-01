const std = @import("std");

pub const TokenTag = enum {
    illegal,

    eof,

    // Identifiers + literals
    ident, // add, foobar, x, y, ...
    int, // 1343456
    //
    // Operators
    assign,
    plus,

    // Delimiters
    comma,
    semicolon,
    lparen,
    rparen,
    lbrace,
    rbrace,

    // Keywords
    function,
    let,
};

pub const Token = union(TokenTag) {
    illegal: u8,

    eof: void,

    // Identifiers + literals
    ident: []const u8, // add, foobar, x, y, ...
    int: []const u8, // 1343456
    //
    // Operators
    assign: void,
    plus: void,

    // Delimiters
    comma: void,
    semicolon: void,
    lparen: void,
    rparen: void,
    lbrace: void,
    rbrace: void,

    // Keywords
    function: void,
    let: void,
};
