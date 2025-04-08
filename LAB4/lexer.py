import re
import enum

class TokenType(enum.Enum):
    # Keywords
    INT = 'int'
    FLOAT = 'float'
    BOOL = 'bool'
    IF = 'if'
    ELSE = 'else'
    WHILE = 'while'
    RETURN = 'return'
    FUNCTION = 'function'
    CASE = 'case'
    DEFAULT = 'default'
    BREAK = 'break'
    SWITCH = 'switch'
    CONTINUE = 'continue'

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
    LBRACKET = '['
    RBRACKET = ']'
    SEMICOLON = ';'
    COMMA = ','
    COLON = ':'

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

    def add_token(self, token_type, value=None):
        """Helper method to add a token to the tokens list"""
        if value is None:
            value = token_type.value
        self.tokens.append(Token(token_type, value, self.line, self.column))
        self.current += 1
        self.column += len(str(value))

    def tokenize(self):
        keywords = {
            'int': TokenType.INT,
            'float': TokenType.FLOAT,
            'bool': TokenType.BOOL,
            'if': TokenType.IF,
            'else': TokenType.ELSE,
            'while': TokenType.WHILE,
            'return': TokenType.RETURN,
            'function': TokenType.FUNCTION,
            'case': TokenType.CASE,
            'default': TokenType.DEFAULT,
            'break': TokenType.BREAK,
            'switch': TokenType.SWITCH,
            'continue': TokenType.CONTINUE
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

            # Handle comments (single-line)
            if char == '/' and self.peek() == '/':
                while self.current < len(self.source_code) and self.source_code[self.current] != '\n':
                    self.current += 1
                continue

            # Handle multi-character operators first
            if char in '=!<>':
                matched = self.tokenize_multi_char_operator()
                if matched:
                    continue

            # Handle numbers (integers and floats)
            if char.isdigit() or (char == '.' and self.peek().isdigit()):
                self.tokenize_number()
                continue

            # Handle identifiers and keywords
            if char.isalpha() or char == '_':
                self.tokenize_identifier(keywords)
                continue

            # Handle single character tokens
            single_char_tokens = {
                '+': TokenType.PLUS,
                '-': TokenType.MINUS,
                '*': TokenType.MULTIPLY,
                '/': TokenType.DIVIDE,
                '(': TokenType.LPAREN,
                ')': TokenType.RPAREN,
                '{': TokenType.LBRACE,
                '}': TokenType.RBRACE,
                '[': TokenType.LBRACKET,
                ']': TokenType.RBRACKET,
                ';': TokenType.SEMICOLON,
                ',': TokenType.COMMA,
                ':': TokenType.COLON
            }

            if char in single_char_tokens:
                self.add_token(single_char_tokens[char])
                continue

            raise ValueError(f'Unexpected character: {char} at line {self.line}, column {self.column}')

        self.tokens.append(Token(TokenType.EOF, '', self.line, self.column))
        return self.tokens

    def tokenize_multi_char_operator(self):
        """Handle multi-character operators like ==, !=, <=, >=, &&, ||"""
        if self.current + 1 < len(self.source_code):
            two_char = self.source_code[self.current:self.current+2]
            operators = {
                '==': TokenType.EQUAL,
                '!=': TokenType.NOT_EQUAL,
                '<=': TokenType.LESS_EQUAL,
                '>=': TokenType.GREATER_EQUAL,
                '&&': TokenType.AND,
                '||': TokenType.OR
            }
            if two_char in operators:
                self.add_token(operators[two_char])
                self.current += 2
                self.column += 2
                return True

        # Handle single character operators if no multi-char match
        operators = {
            '=': TokenType.ASSIGN,
            '<': TokenType.LESS_THAN,
            '>': TokenType.GREATER_THAN,
            '!': TokenType.NOT
        }
        if self.source_code[self.current] in operators:
            self.add_token(operators[self.source_code[self.current]])
            return True
        
        return False

    def tokenize_number(self):
        """Tokenize integers and floating point numbers"""
        start = self.current
        is_float = False

        while self.current < len(self.source_code):
            char = self.source_code[self.current]
            if char.isdigit():
                self.current += 1
                self.column += 1
            elif char == '.' and not is_float:
                is_float = True
                self.current += 1
                self.column += 1
            else:
                break

        value = self.source_code[start:self.current]
        self.tokens.append(Token(TokenType.NUMBER, value, self.line, self.column - len(value)))

    def tokenize_identifier(self, keywords):
        """Tokenize identifiers and keywords"""
        start = self.current
        while self.current < len(self.source_code):
            char = self.source_code[self.current]
            if char.isalnum() or char == '_':
                self.current += 1
                self.column += 1
            else:
                break

        value = self.source_code[start:self.current]
        token_type = keywords.get(value, TokenType.IDENTIFIER)
        self.tokens.append(Token(token_type, value, self.line, self.column - len(value)))

    def peek(self, distance=1):
        """Look ahead in the source code without consuming characters"""
        peek_pos = self.current + distance
        if peek_pos >= len(self.source_code):
            return '\0'
        return self.source_code[peek_pos]