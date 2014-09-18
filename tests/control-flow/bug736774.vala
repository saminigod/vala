bool destroyed = false;

class Foo : Object {
    ~Foo() {
		destroyed = true;
    }
}

Foo may_fail () throws Error {
	return new Foo ();
}

void func (Foo x) {
}

void main() {
    try {
        func (may_fail ());
    } catch {
    }

	assert (destroyed);
}
