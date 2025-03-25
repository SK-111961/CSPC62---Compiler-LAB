from lexer import Lexer
from parser import compile_source

def main():
    # Sample source code
    source_code = '''
    function test() {
        int x = 10;
        int y = 20;
        int z = x + y * 2;
        
        if (z > 30) {
            int a = 5;
        } else {
            int b = 7;
        }
        
        while (x < 15) {
            x = x + 1;
        }
    }
    '''
    
    print("Source Code:")
    print(source_code)
    
    print("\nThree-Address Codes:")
    three_address_codes = compile_source(source_code)
    for code in three_address_codes:
        print(code)

if __name__ == "__main__":
    main()