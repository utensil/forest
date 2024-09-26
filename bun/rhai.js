import init, { compile_script, run_script } from '../lib/rhaiscript/pkg'

await init()

const script = `\
fn run(a) {
    let b = a + 1;
    print("Hello world! a = " + a);
}
run(10);
`

console.log(compile_script(script))

console.log(
    run_script(
        script,
        (s) => console.log(s),
        (S) => console.debug(s),
    ),
)
