# CSPC62-Compiler LAB


A compiler implementation featuring a lexical analyzer (lexer) and syntax analyzer (parser) for a custom programming language.

## Overview

This project implements the front-end components of a compiler:

- **Lexical Analyzer (Lexer)**: Transforms source code into tokens
- **Syntax Analyzer (Parser)**: Builds an abstract syntax tree (AST) from tokens

## Features

- Custom language grammar and syntax rules
- Error detection with meaningful messages
- Abstract Syntax Tree (AST) generation
- Support for common programming constructs:
  - Variable declarations and assignments
  - Control flow statements (if-else, loops)
  - Function definitions and calls
  - Basic expressions and operations

## Project Structure

```
├── LAB1/
│   ├── calc.sk
│   ├── features.sk
│   ├── run.sh
│   ├── search.sk
│   ├── sort.sk
│   ├── test1.sk
│   └── test2.sk
├── LAB2/
│   ├── lexer.l
│   ├── parsery
│   ├── run.sh
│   └── test.sk
├── LAB3/
│   ├── lexer.l
│   ├── parsery
│   ├── run.sh
│   ├── test.sk
│   └── test2.sk
├── LAB.pdf
└── README.md
```

## Installation

```bash
# Clone the repository
git clone https://github.com/SK-111961/CSPC62---Compiler-LAB
cd compiler-project

# Navigate Lab
cd CSPC62---Compiler-LAB
cd LAB#

# Build the compiler
./run.sh <argument_file>
```

## Implementation Details

### Lexer

The lexical analyzer breaks down source code into tokens, identifying:
- Keywords (if, else, while, function, return)
- Identifiers (variable and function names)
- Literals (integers, floats, strings)
- Operators (+, -, *, /, =, ==, etc.)
- Punctuation marks (parentheses, braces, semicolons)

### Parser

The parser uses recursive descent parsing to build an abstract syntax tree from the tokens provided by the lexer. It handles:
- Expression parsing with operator precedence
- Statement parsing (declarations, control flow, etc.)
- Function definitions
- Error recovery and reporting

## Future Enhancements

- Semantic analysis
- Intermediate code generation
- Code optimization
- Target code generation for a specific architecture


## License

This project is licensed under the MIT License - see the LICENSE file for details.