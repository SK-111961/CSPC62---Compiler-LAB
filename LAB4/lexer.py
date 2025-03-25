import re
import enum

class TokenType(enum.Enum):
    # Keywords
    INT = 'INT'
    FLOAT = 'FLOAT'
    BOOL = 'BOOL'
    IF = 'IF'
    ELSE = 'ELSE'
    WHILE = 'WHILE'
    RETURN = 'RETURN'
    FUNCTION = 'FUNCTION'

    # Operators
    PLUS = '+'
    MINUS = '-'
    MULTIPLY = '*'
    DIVIDE = '/'
    ASSIGN = '='
    
    # Comparison Operators
    EQUAL = '=='
    NOT_EQUAL = '!='
    LESS_THAN = '<'
    GREATER_THAN = '>'
    LESS_EQUAL = '<='
    GREATER_EQUAL = '>='

    # Logical Operators
    AND = '&&'
    OR = '||'
    NOT = '!'

    # Punctuation
    LPAREN = '('
    RPAREN = ')'
    LBRACE = '{'
    RBRACE = '}'
    SEMICOLON = ';'
    COMMA = ','

    # Literals and Identifiers
    NUMBER = 'NUMBER'
    IDENTIFIER = 'IDENTIFIER'
    
    # End of File
    EOF = 'EOF'

class Token:
    def __init__(self, type, value, line=0, column=0):
        self.type = type
        self.value = value
        self.line = line
        self.column = column

    def __repr__(self):
        return f'Token({self.type}, {self.value}, Line: {self.line}, Column: {self.column})'

class Lexer:
    def __init__(self, source_code):
        self.source_code = source_code
        self.tokens = []
        self.current = 0
        self.line = 1
        self.column = 1

    def tokenize(self):
        keywords = {
            'int': TokenType.INT,
            'float': TokenType.FLOAT,
            'bool': TokenType.BOOL,
            'if': TokenType.IF,
            'else': TokenType.ELSE,
            'while': TokenType.WHILE,
            'return': TokenType.RETURN,
            'function': TokenType.FUNCTION
        }

        while self.current < len(self.source_code):
            char = self.source_code[self.current]

            # Skip whitespace
            if char.isspace():
                if char == '\n':
                    self.line += 1
                    self.column = 1
                else:
                    self.column += 1
                self.current += 1
                continue

            # Numbers
            if char.isdigit() or (char == '.' and self.peek().isdigit()):
                self.tokenize_number()
                continue

            # Identifiers and Keywords
            if char.isalpha() or char == '_':
                self.tokenize_identifier(keywords)
                continue

            # Multi-character operators
            if char in '=!<>':
                self.tokenize_comparison_operator()
                continue

            # Single character tokens
            single_char_tokens = {
                '+': TokenType.PLUS,
                '-': TokenType.MINUS,
                '*': TokenType.MULTIPLY,
                '/': TokenType.DIVIDE,
                '=': TokenType.ASSIGN,
                '(': TokenType.LPAREN,
                ')': TokenType.RPAREN,
                '{': TokenType.LBRACE,
                '}': TokenType.RBRACE,
                ';': TokenType.SEMICOLON,
                ',': TokenType.COMMA
            }

            if char in single_char_tokens:
                self.tokens.append(Token(single_char_tokens[char], char, self.line, self.column))
                self.current += 1
                self.column += 1
                continue

            raise ValueError(f'Unexpected character: {char} at line {self.line}, column {self.column}')

        self.tokens.append(Token(TokenType.EOF, '', self.line, self.column))
        return self.tokens

    def tokenize_number(self):
        start = self.current
        is_float = False

        # Check if it's a float
        while self.current < len(self.source_code) and (self.source_code[self.current].isdigit() or self.source_code[self.current] == '.'):
            if self.source_code[self.current] == '.':
                is_float = True
            self.current += 1

        value = self.source_code[start:self.current]
        self.tokens.append(Token(TokenType.NUMBER, value, self.line, self.column))
        self.column += len(value)

    def tokenize_identifier(self, keywords):
        start = self.current
        while self.current < len(self.source_code) and (self.source_code[self.current].isalnum() or self.source_code[self.current] == '_'):
            self.current += 1

        value = self.source_code[start:self.current]
        token_type = keywords.get(value, TokenType.IDENTIFIER)
        self.tokens.append(Token(token_type, value, self.line, self.column))
        self.column += len(value)

    def tokenize_comparison_operator(self):
        if self.current + 1 < len(self.source_code):
            two_char_ops = {
                '==': TokenType.EQUAL,
                '!=': TokenType.NOT_EQUAL,
                '<=': TokenType.LESS_EQUAL,
                '>=': TokenType.GREATER_EQUAL
            }
            
            two_chars = self.source_code[self.current:self.current+2]
            if two_chars in two_char_ops:
                self.tokens.append(Token(two_char_ops[two_chars], two_chars, self.line, self.column))
                self.current += 2
                self.column += 2
                return

        single_char_ops = {
            '=': TokenType.ASSIGN,
            '<': TokenType.LESS_THAN,
            '>': TokenType.GREATER_THAN
        }

        self.tokens.append(Token(single_char_ops[self.source_code[self.current]], 
                                 self.source_code[self.current], 
                                 self.line, self.column))
        self.current += 1
        self.column += 1

    def peek(self, distance=1):
        peek_pos = self.current + distance
        if peek_pos >= len(self.source_code):
            return '\0'
        return self.source_code[peek_pos]