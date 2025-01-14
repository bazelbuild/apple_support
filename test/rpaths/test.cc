int foo();
int bar();
int baz();
int main() {
  int result = foo() + bar() + baz();
  if (result == 56) {
    return 0;
  } else {
    return result;
  }
}
