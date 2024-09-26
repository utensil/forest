import init, { compile_script } from '../lib/rhaiscript/pkg'

await init()

console.log(compile_script(`\
fn run(a) {
    let b = a + 1;
    print("Hello world! a = " + a);
}
run(10);
`))
