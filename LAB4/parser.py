from lexer import Lexer, TokenType
import enum

class NodeType(enum.Enum):
    PROGRAM = 'PROGRAM'
    FUNCTION_DECLARATION = 'FUNCTION_DECLARATION'
    VARIABLE_DECLARATION = 'VARIABLE_DECLARATION'
    ASSIGNMENT = 'ASSIGNMENT'
    BINARY_OPERATION = 'BINARY_OPERATION'
    COMPARISON_OPERATION = 'COMPARISON_OPERATION'
    IF_STATEMENT = 'IF_STATEMENT'
    WHILE_STATEMENT = 'WHILE_STATEMENT'
    FUNCTION_CALL = 'FUNCTION_CALL'
    RETURN_STATEMENT = 'RETURN_STATEMENT'
    IDENTIFIER = 'IDENTIFIER'
    NUMBER = 'NUMBER'

class ASTNode:
    def __init__(self, type, value=None, left=None, right=None):
        self.type = type
        self.value = value
        self.left = left
        self.right = right
        self.children = []

class ThreeAddressCodeGenerator:
    def __init__(self):
        self.temp_counter = 0
        self.label_counter = 0
        self.code = []
        self.symbol_table = {}

    def new_temp(self):
        self.temp_counter += 1
        return f't{self.temp_counter}'

    def new_label(self):
        self.label_counter += 1
        return f'L{self.label_counter}'

    def generate_code(self, node):
        if not node:
            return None

        if node.type == NodeType.BINARY_OPERATION:
            left_temp = self.generate_code(node.left)
            right_temp = self.generate_code(node.right)
            result_temp = self.new_temp()
            
            self.code.append(f'{result_temp} = {left_temp} {node.value} {right_temp}')
            return result_temp

        if node.type == NodeType.COMPARISON_OPERATION:
            left_temp = self.generate_code(node.left)
            right_temp = self.generate_code(node.right)
            result_temp = self.new_temp()
            
            self.code.append(f'{result_temp} = {left_temp} {node.value} {right_temp}')
            return result_temp

        if node.type == NodeType.ASSIGNMENT:
            value_temp = self.generate_code(node.right)
            self.code.append(f'{node.left.value} = {value_temp}')
            return node.left.value

        if node.type == NodeType.NUMBER:
            return node.value

        if node.type == NodeType.IDENTIFIER:
            return node.value

        # Recursive code generation for children
        if hasattr(node, 'children'):
            for child in node.children:
                self.generate_code(child)

        return None

class Parser:
    def __init__(self, tokens):
        self.tokens = tokens
        self.current = 0
        self.code_generator = ThreeAddressCodeGenerator()

    def parse(self):
        return self.program()

    def program(self):
        program_node = ASTNode(NodeType.PROGRAM)
        while self.current < len(self.tokens) and self.tokens[self.current].type != TokenType.EOF:
            if self.tokens[self.current].type == TokenType.FUNCTION:
                program_node.children.append(self.function_declaration())
            else:
                # For simplicity, we'll handle top-level statements
                program_node.children.append(self.statement())
        return program_node

    def function_declaration(self):
        self.consume(TokenType.FUNCTION)
        name = self.consume(TokenType.IDENTIFIER)
        
        self.consume(TokenType.LPAREN)
        # TODO: Handle function parameters
        self.consume(TokenType.RPAREN)
        
        func_node = ASTNode(NodeType.FUNCTION_DECLARATION, name.value)
        func_node.children.append(self.block())
        return func_node

    def block(self):
        self.consume(TokenType.LBRACE)
        block_node = ASTNode(NodeType.PROGRAM)
        
        while self.tokens[self.current].type != TokenType.RBRACE:
            block_node.children.append(self.statement())
        
        self.consume(TokenType.RBRACE)
        return block_node

    def statement(self):
        token = self.tokens[self.current]
        
        if token.type in [TokenType.INT, TokenType.FLOAT, TokenType.BOOL]:
            return self.variable_declaration()
        
        if token.type == TokenType.IF:
            return self.if_statement()
        
        if token.type == TokenType.WHILE:
            return self.while_statement()
        
        if token.type == TokenType.IDENTIFIER:
            if self.peek(1).type == TokenType.ASSIGN:
                return self.assignment()
            return self.expression()
        
        raise ValueError(f'Unexpected token: {token}')

    def variable_declaration(self):
        type_token = self.consume([TokenType.INT, TokenType.FLOAT, TokenType.BOOL])
        name = self.consume(TokenType.IDENTIFIER)
        
        decl_node = ASTNode(NodeType.VARIABLE_DECLARATION, type_token.type)
        decl_node.children.append(ASTNode(NodeType.IDENTIFIER, name.value))
        
        if self.tokens[self.current].type == TokenType.ASSIGN:
            self.consume(TokenType.ASSIGN)
            decl_node.children.append(self.expression())
        
        self.consume(TokenType.SEMICOLON)
        return decl_node

    def assignment(self):
        left = self.consume(TokenType.IDENTIFIER)
        self.consume(TokenType.ASSIGN)
        right = self.expression()
        self.consume(TokenType.SEMICOLON)
        
        return ASTNode(NodeType.ASSIGNMENT, 
                       left=ASTNode(NodeType.IDENTIFIER, left.value), 
                       right=right)

    def if_statement(self):
        self.consume(TokenType.IF)
        self.consume(TokenType.LPAREN)
        condition = self.comparison_expression()
        self.consume(TokenType.RPAREN)
        
        true_block = self.block()
        
        if self.tokens[self.current].type == TokenType.ELSE:
            self.consume(TokenType.ELSE)
            false_block = self.block()
        else:
            false_block = None
        
        if_node = ASTNode(NodeType.IF_STATEMENT, 
                          left=condition, 
                          right=true_block)
        if false_block:
            if_node.children.append(false_block)
        
        return if_node

    def while_statement(self):
        self.consume(TokenType.WHILE)
        self.consume(TokenType.LPAREN)
        condition = self.comparison_expression()
        self.consume(TokenType.RPAREN)
        
        body = self.block()
        
        return ASTNode(NodeType.WHILE_STATEMENT, 
                       left=condition, 
                       right=body)

    def comparison_expression(self):
        left = self.additive_expression()
        
        comparison_ops = [
            TokenType.GREATER_THAN, TokenType.LESS_THAN, 
            TokenType.EQUAL, TokenType.NOT_EQUAL,
            TokenType.GREATER_EQUAL, TokenType.LESS_EQUAL
        ]
        
        if self.current < len(self.tokens) and self.tokens[self.current].type in comparison_ops:
            operator = self.consume(comparison_ops)
            right = self.additive_expression()
            return ASTNode(NodeType.COMPARISON_OPERATION, 
                           operator.value, 
                           left=left, 
                           right=right)
        
        return left

    def expression(self):
        return self.comparison_expression()

    def additive_expression(self):
        left = self.multiplicative_expression()
        
        while self.current < len(self.tokens) and self.tokens[self.current].type in [TokenType.PLUS, TokenType.MINUS]:
            operator = self.consume([TokenType.PLUS, TokenType.MINUS])
            right = self.multiplicative_expression()
            left = ASTNode(NodeType.BINARY_OPERATION, 
                           operator.value, 
                           left=left, 
                           right=right)
        
        return left

    def multiplicative_expression(self):
        left = self.primary_expression()
        
        while self.current < len(self.tokens) and self.tokens[self.current].type in [TokenType.MULTIPLY, TokenType.DIVIDE]:
            operator = self.consume([TokenType.MULTIPLY, TokenType.DIVIDE])
            right = self.primary_expression()
            left = ASTNode(NodeType.BINARY_OPERATION, 
                           operator.value, 
                           left=left, 
                           right=right)
        
        return left

    def primary_expression(self):
        token = self.tokens[self.current]
        
        if token.type == TokenType.NUMBER:
            self.consume(TokenType.NUMBER)
            return ASTNode(NodeType.NUMBER, token.value)
        
        if token.type == TokenType.IDENTIFIER:
            self.consume(TokenType.IDENTIFIER)
            return ASTNode(NodeType.IDENTIFIER, token.value)
        
        if token.type == TokenType.LPAREN:
            self.consume(TokenType.LPAREN)
            expr = self.expression()
            self.consume(TokenType.RPAREN)
            return expr
        
        raise ValueError(f'Unexpected token in primary expression: {token}')

    def consume(self, types):
        if isinstance(types, list):
            if self.tokens[self.current].type not in types:
                raise ValueError(f'Expected one of {types}, got {self.tokens[self.current]}')
        else:
            if self.tokens[self.current].type != types:
                raise ValueError(f'Expected {types}, got {self.tokens[self.current]}')
        
        token = self.tokens[self.current]
        self.current += 1
        return token

    def peek(self, distance=1):
        peek_pos = self.current + distance
        if peek_pos >= len(self.tokens):
            return None
        return self.tokens[peek_pos]

def compile_source(source_code):
    lexer = Lexer(source_code)
    tokens = lexer.tokenize()
    
    parser = Parser(tokens)
    ast = parser.parse()
    
    code_generator = ThreeAddressCodeGenerator()
    
    def generate_three_address_code(node):
        if not node:
            return
        
        if node.children:
            for child in node.children:
                generate_three_address_code(child)
        
        # Generate three-address code for the current node
        code_generator.generate_code(node)
    
    generate_three_address_code(ast)
    
    return code_generator.code