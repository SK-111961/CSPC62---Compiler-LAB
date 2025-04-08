from lexer import Lexer
from parser import compile_source

def main():
    # Sample source code
    source_code = """
    function expressions() {
    int a = 10, b = 20;
    float c = 3.5;
    bool d = true;
    

    int x = (a + b) * (a - b) / 2;
    float y = c * (x + a);
    
    if (x > y && d || !(a == b)) {
        y = y + 1.0;
    }
    
    int[5] arr;
    arr[0] = a;
    arr[1] = arr[0] + b;
    
    // Function call
    int z = factorial(a);
    }
    """

    
    print("Source Code:")
    print(source_code)
    
    print("\nThree-Address Codes:")
    three_address_codes = compile_source(source_code)
    for code in three_address_codes:
        print(code)

if __name__ == "__main__":
    main()