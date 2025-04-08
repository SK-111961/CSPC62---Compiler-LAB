from lexer import Lexer, TokenType
import enum


class NodeType(enum.Enum):
    PROGRAM = 'PROGRAM'
    FUNCTION_DECLARATION = 'FUNCTION_DECLARATION'
    VARIABLE_DECLARATION = 'VARIABLE_DECLARATION'
    ARRAY_DECLARATION = 'ARRAY_DECLARATION'
    ASSIGNMENT = 'ASSIGNMENT'
    BINARY_OPERATION = 'BINARY_OPERATION'
    UNARY_OPERATION = 'UNARY_OPERATION'
    COMPARISON_OPERATION = 'COMPARISON_OPERATION'
    LOGICAL_OPERATION = 'LOGICAL_OPERATION'
    IF_STATEMENT = 'IF_STATEMENT'
    WHILE_STATEMENT = 'WHILE_STATEMENT'
    SWITCH_STATEMENT = 'SWITCH_STATEMENT'
    CASE_STATEMENT = 'CASE_STATEMENT'
    DEFAULT_CASE = 'DEFAULT_CASE'
    BREAK_STATEMENT = 'BREAK_STATEMENT'
    CONTINUE_STATEMENT = 'CONTINUE_STATEMENT'
    FUNCTION_CALL = 'FUNCTION_CALL'
    RETURN_STATEMENT = 'RETURN_STATEMENT'
    IDENTIFIER = 'IDENTIFIER'
    NUMBER = 'NUMBER'
    ARRAY_ACCESS = 'ARRAY_ACCESS'
    PARAMETERS = 'PARAMETERS'
    FUNCTION_PARAM = 'FUNCTION_PARAM'

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
        self.pending_jumps = {}

    def new_temp(self):
        self.temp_counter += 1
        return f't{self.temp_counter}'

    def new_label(self):
        self.label_counter += 1
        return f'L{self.label_counter}'

    def backpatch(self, label, locations):
        for loc in locations:
            if '?' in self.code[loc]:
                self.code[loc] = self.code[loc].replace('?', label)

    def generate_code(self, node):
        if not node:
            return None

        if node.type == NodeType.BINARY_OPERATION:
            left_temp = self.generate_code(node.left)
            right_temp = self.generate_code(node.right)
            result_temp = self.new_temp()
            self.code.append(f'{result_temp} = {left_temp} {node.value} {right_temp}')
            return result_temp

        if node.type == NodeType.UNARY_OPERATION:
            operand_temp = self.generate_code(node.left)
            result_temp = self.new_temp()
            self.code.append(f'{result_temp} = {node.value}{operand_temp}')
            return result_temp

        if node.type == NodeType.COMPARISON_OPERATION:
            left_temp = self.generate_code(node.left)
            right_temp = self.generate_code(node.right)
            result_temp = self.new_temp()
            self.code.append(f'{result_temp} = {left_temp} {node.value} {right_temp}')
            return result_temp

        if node.type == NodeType.LOGICAL_OPERATION:
            left_temp = self.generate_code(node.left)
            false_label = self.new_label()
            end_label = self.new_label()
            
            if node.value == '&&':
                loc = len(self.code)
                self.code.append(f'if {left_temp} == false goto ?')
                self.pending_jumps.setdefault(false_label, []).append(loc)
                right_temp = self.generate_code(node.right)
                result_temp = self.new_temp()
                self.code.append(f'{result_temp} = {right_temp}')
                self.code.append(f'goto {end_label}')
                self.backpatch(false_label, self.pending_jumps[false_label])
                self.code.append(f'label {false_label}')
                self.code.append(f'{result_temp} = false')
                self.code.append(f'label {end_label}')
                return result_temp
            else:  # OR operation
                true_label = self.new_label()
                loc = len(self.code)
                self.code.append(f'if {left_temp} == true goto ?')
                self.pending_jumps.setdefault(true_label, []).append(loc)
                right_temp = self.generate_code(node.right)
                result_temp = self.new_temp()
                self.code.append(f'{result_temp} = {right_temp}')
                self.code.append(f'goto {end_label}')
                self.backpatch(true_label, self.pending_jumps[true_label])
                self.code.append(f'label {true_label}')
                self.code.append(f'{result_temp} = true')
                self.code.append(f'label {end_label}')
                return result_temp

        if node.type == NodeType.ASSIGNMENT:
            value_temp = self.generate_code(node.right)
            if node.left.type == NodeType.ARRAY_ACCESS:
                index_temp = self.generate_code(node.left.left)
                self.code.append(f'{node.left.value}[{index_temp}] = {value_temp}')
            else:
                self.code.append(f'{node.left.value} = {value_temp}')
            return node.left.value

        if node.type == NodeType.IF_STATEMENT:
            condition_temp = self.generate_code(node.left)
            false_label = self.new_label()
            end_label = self.new_label()
            
            # If condition false, jump to else/false_label
            loc = len(self.code)
            self.code.append(f'if {condition_temp} == false goto ?')
            self.pending_jumps.setdefault(false_label, []).append(loc)
            
            # Generate true block
            self.generate_code(node.right)
            
            # If there's an else, jump over it
            if len(node.children) > 0:
                self.code.append(f'goto {end_label}')
            
            # Backpatch the false label
            self.backpatch(false_label, self.pending_jumps[false_label])
            self.code.append(f'label {false_label}')
            
            # Generate else block if exists
            if len(node.children) > 0:
                self.generate_code(node.children[0])
                self.code.append(f'label {end_label}')
            
            return None

        if node.type == NodeType.WHILE_STATEMENT:
            start_label = self.new_label()
            condition_label = self.new_label()
            end_label = self.new_label()
            
            self.code.append(f'label {start_label}')
            self.code.append(f'goto {condition_label}')
            self.code.append(f'label {condition_label}')
            
            condition_temp = self.generate_code(node.left)
            loc = len(self.code)
            self.code.append(f'if {condition_temp} == false goto ?')
            self.pending_jumps.setdefault(end_label, []).append(loc)
            
            self.generate_code(node.right)
            self.code.append(f'goto {start_label}')
            self.code.append(f'label {end_label}')
            
            return None

        if node.type == NodeType.SWITCH_STATEMENT:
            expr_temp = self.generate_code(node.left)
            end_label = self.new_label()
            case_labels = []
            
            for case_node in node.children:
                if case_node.type == NodeType.CASE_STATEMENT:
                    case_label = self.new_label()
                    case_labels.append(case_label)
                    case_value = self.generate_code(case_node)
                    loc = len(self.code)
                    self.code.append(f'if {expr_temp} == {case_value} goto ?')
                    self.pending_jumps.setdefault(case_label, []).append(loc)
            
            # Default case if exists
            default_label = None
            if len(node.children) > len(case_labels):
                default_label = self.new_label()
                self.code.append(f'goto {default_label}')
            
            # Generate case blocks
            for i, case_node in enumerate(node.children):
                if case_node.type == NodeType.CASE_STATEMENT:
                    self.backpatch(case_labels[i], self.pending_jumps[case_labels[i]])
                    self.code.append(f'label {case_labels[i]}')
                    self.generate_code(case_node.children[0])
                    self.code.append(f'goto {end_label}')
                elif case_node.type == NodeType.DEFAULT_CASE:
                    if default_label:
                        self.code.append(f'label {default_label}')
                        self.generate_code(case_node.children[0])
            
            self.code.append(f'label {end_label}')
            return None

        if node.type == NodeType.NUMBER:
            return node.value

        if node.type == NodeType.IDENTIFIER:
            return node.value

        if node.type == NodeType.ARRAY_ACCESS:
            index_temp = self.generate_code(node.left)
            temp = self.new_temp()
            self.code.append(f'{temp} = {node.value}[{index_temp}]')
            return temp

        if node.type == NodeType.FUNCTION_CALL:
            arg_temps = [self.generate_code(child) for child in node.children]
            result_temp = self.new_temp()
            self.code.append(f'{result_temp} = call {node.value}({", ".join(arg_temps)})')
            return result_temp

        if node.type == NodeType.RETURN_STATEMENT:
            if node.left:
                value_temp = self.generate_code(node.left)
                self.code.append(f'return {value_temp}')
            else:
                self.code.append('return')
            return None

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
                program_node.children.append(self.statement())
        return program_node

    def function_declaration(self):
        self.consume(TokenType.FUNCTION)
        name = self.consume(TokenType.IDENTIFIER)
        
        self.consume(TokenType.LPAREN)
        params_node = ASTNode(NodeType.PARAMETERS)
        while self.tokens[self.current].type != TokenType.RPAREN:
            param_type = self.consume([TokenType.INT, TokenType.FLOAT, TokenType.BOOL])
            param_name = self.consume(TokenType.IDENTIFIER)
            param_node = ASTNode(NodeType.FUNCTION_PARAM, param_type.value)
            param_node.children.append(ASTNode(NodeType.IDENTIFIER, param_name.value))
            params_node.children.append(param_node)
            
            if self.tokens[self.current].type == TokenType.COMMA:
                self.consume(TokenType.COMMA)
        self.consume(TokenType.RPAREN)
        
        func_node = ASTNode(NodeType.FUNCTION_DECLARATION, name.value)
        func_node.children.append(params_node)
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
            if self.peek(1).type == TokenType.IDENTIFIER and self.peek(2).type == TokenType.LBRACKET:
                return self.array_declaration()
            return self.variable_declaration()
        
        if token.type == TokenType.IF:
            return self.if_statement()
        
        if token.type == TokenType.WHILE:
            return self.while_statement()
        
        if token.type == TokenType.SWITCH:
            return self.switch_statement()
        
        if token.type == TokenType.BREAK:
            return self.break_statement()
        
        if token.type == TokenType.CONTINUE:
            return self.continue_statement()
        
        if token.type == TokenType.RETURN:
            return self.return_statement()
        
        if token.type == TokenType.IDENTIFIER:
            if self.peek(1).type == TokenType.ASSIGN:
                return self.assignment()
            elif self.peek(1).type == TokenType.LPAREN:
                return self.function_call()
            elif self.peek(1).type == TokenType.LBRACKET:
                return self.array_assignment()
            return self.expression()
        
        raise ValueError(f'Unexpected token: {token}')

    def array_declaration(self):
        type_token = self.consume([TokenType.INT, TokenType.FLOAT, TokenType.BOOL])
        name = self.consume(TokenType.IDENTIFIER)
        self.consume(TokenType.LBRACKET)
        size = self.consume(TokenType.NUMBER)
        self.consume(TokenType.RBRACKET)
        
        decl_node = ASTNode(NodeType.ARRAY_DECLARATION, type_token.value)
        decl_node.children.append(ASTNode(NodeType.IDENTIFIER, name.value))
        decl_node.children.append(ASTNode(NodeType.NUMBER, size.value))
        
        if self.tokens[self.current].type == TokenType.ASSIGN:
            self.consume(TokenType.ASSIGN)
            self.consume(TokenType.LBRACE)
            while self.tokens[self.current].type != TokenType.RBRACE:
                decl_node.children.append(self.expression())
                if self.tokens[self.current].type == TokenType.COMMA:
                    self.consume(TokenType.COMMA)
            self.consume(TokenType.RBRACE)
        
        self.consume(TokenType.SEMICOLON)
        return decl_node

    def array_assignment(self):
        name = self.consume(TokenType.IDENTIFIER)
        self.consume(TokenType.LBRACKET)
        index = self.expression()
        self.consume(TokenType.RBRACKET)
        self.consume(TokenType.ASSIGN)
        value = self.expression()
        self.consume(TokenType.SEMICOLON)
        
        return ASTNode(NodeType.ASSIGNMENT,
                      left=ASTNode(NodeType.ARRAY_ACCESS, name.value, left=index),
                      right=value)

    def variable_declaration(self):
        type_token = self.consume([TokenType.INT, TokenType.FLOAT, TokenType.BOOL])
        name = self.consume(TokenType.IDENTIFIER)
        
        decl_node = ASTNode(NodeType.VARIABLE_DECLARATION, type_token.value)
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
        condition = self.logical_expression()
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
        condition = self.logical_expression()
        self.consume(TokenType.RPAREN)
        
        body = self.block()
        
        return ASTNode(NodeType.WHILE_STATEMENT, 
                      left=condition, 
                      right=body)

    def switch_statement(self):
        self.consume(TokenType.SWITCH)
        self.consume(TokenType.LPAREN)
        expr = self.expression()
        self.consume(TokenType.RPAREN)
        self.consume(TokenType.LBRACE)
        
        cases = []
        default_case = None
        
        while self.tokens[self.current].type == TokenType.CASE:
            cases.append(self.case_statement())
        
        if self.tokens[self.current].type == TokenType.DEFAULT:
            default_case = self.default_case()
        
        self.consume(TokenType.RBRACE)
        
        switch_node = ASTNode(NodeType.SWITCH_STATEMENT, left=expr)
        switch_node.children = cases
        if default_case:
            switch_node.children.append(default_case)
        
        return switch_node

    def case_statement(self):
        self.consume(TokenType.CASE)
        value = self.expression()
        self.consume(TokenType.COLON)
        
        statements = []
        while (self.tokens[self.current].type not in 
               [TokenType.CASE, TokenType.DEFAULT, TokenType.RBRACE]):
            statements.append(self.statement())
        
        case_node = ASTNode(NodeType.CASE_STATEMENT, value=value.value)
        block_node = ASTNode(NodeType.PROGRAM)
        block_node.children = statements
        case_node.children.append(block_node)
        
        return case_node

    def default_case(self):
        self.consume(TokenType.DEFAULT)
        self.consume(TokenType.COLON)
        
        statements = []
        while self.tokens[self.current].type != TokenType.RBRACE:
            statements.append(self.statement())
        
        default_node = ASTNode(NodeType.DEFAULT_CASE)
        block_node = ASTNode(NodeType.PROGRAM)
        block_node.children = statements
        default_node.children.append(block_node)
        
        return default_node

    def break_statement(self):
        self.consume(TokenType.BREAK)
        self.consume(TokenType.SEMICOLON)
        return ASTNode(NodeType.BREAK_STATEMENT)

    def continue_statement(self):
        self.consume(TokenType.CONTINUE)
        self.consume(TokenType.SEMICOLON)
        return ASTNode(NodeType.CONTINUE_STATEMENT)

    def return_statement(self):
        self.consume(TokenType.RETURN)
        if self.tokens[self.current].type != TokenType.SEMICOLON:
            expr = self.expression()
            self.consume(TokenType.SEMICOLON)
            return ASTNode(NodeType.RETURN_STATEMENT, left=expr)
        self.consume(TokenType.SEMICOLON)
        return ASTNode(NodeType.RETURN_STATEMENT)

    def function_call(self):
        name = self.consume(TokenType.IDENTIFIER)
        self.consume(TokenType.LPAREN)
        
        args_node = ASTNode(NodeType.PARAMETERS)
        while self.tokens[self.current].type != TokenType.RPAREN:
            args_node.children.append(self.expression())
            if self.tokens[self.current].type == TokenType.COMMA:
                self.consume(TokenType.COMMA)
        
        self.consume(TokenType.RPAREN)
        self.consume(TokenType.SEMICOLON)
        
        call_node = ASTNode(NodeType.FUNCTION_CALL, name.value)
        call_node.children = args_node.children
        return call_node

    def expression(self):
        return self.logical_expression()

    def logical_expression(self):
        left = self.comparison_expression()
        
        while self.current < len(self.tokens) and self.tokens[self.current].type in [TokenType.AND, TokenType.OR]:
            op = self.consume([TokenType.AND, TokenType.OR])
            right = self.comparison_expression()
            left = ASTNode(NodeType.LOGICAL_OPERATION, op.value, left=left, right=right)
        
        return left

    def comparison_expression(self):
        left = self.additive_expression()
        
        comparison_ops = [
            TokenType.EQUAL, TokenType.NOT_EQUAL,
            TokenType.LESS_THAN, TokenType.GREATER_THAN,
            TokenType.LESS_EQUAL, TokenType.GREATER_EQUAL
        ]
        
        if self.current < len(self.tokens) and self.tokens[self.current].type in comparison_ops:
            op = self.consume(comparison_ops)
            right = self.additive_expression()
            return ASTNode(NodeType.COMPARISON_OPERATION, op.value, left=left, right=right)
        
        return left

    def additive_expression(self):
        left = self.multiplicative_expression()
        
        while self.current < len(self.tokens) and self.tokens[self.current].type in [TokenType.PLUS, TokenType.MINUS]:
            op = self.consume([TokenType.PLUS, TokenType.MINUS])
            right = self.multiplicative_expression()
            left = ASTNode(NodeType.BINARY_OPERATION, op.value, left=left, right=right)
        
        return left

    def multiplicative_expression(self):
        left = self.unary_expression()
        
        while self.current < len(self.tokens) and self.tokens[self.current].type in [TokenType.MULTIPLY, TokenType.DIVIDE]:
            op = self.consume([TokenType.MULTIPLY, TokenType.DIVIDE])
            right = self.unary_expression()
            left = ASTNode(NodeType.BINARY_OPERATION, op.value, left=left, right=right)
        
        return left

    def unary_expression(self):
        if self.tokens[self.current].type in [TokenType.NOT, TokenType.MINUS]:
            op = self.consume([TokenType.NOT, TokenType.MINUS])
            operand = self.unary_expression()
            return ASTNode(NodeType.UNARY_OPERATION, op.value, left=operand)
        return self.primary_expression()

    def primary_expression(self):
        token = self.tokens[self.current]
        
        if token.type == TokenType.NUMBER:
            self.consume(TokenType.NUMBER)
            return ASTNode(NodeType.NUMBER, token.value)
        
        if token.type == TokenType.IDENTIFIER:
            if self.peek(1).type == TokenType.LPAREN:
                return self.function_call()
            elif self.peek(1).type == TokenType.LBRACKET:
                name = self.consume(TokenType.IDENTIFIER)
                self.consume(TokenType.LBRACKET)
                index = self.expression()
                self.consume(TokenType.RBRACKET)
                return ASTNode(NodeType.ARRAY_ACCESS, name.value, left=index)
            else:
                name = self.consume(TokenType.IDENTIFIER)
                return ASTNode(NodeType.IDENTIFIER, name.value)
        
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
    code_generator.generate_code(ast)
    
    return code_generator.code