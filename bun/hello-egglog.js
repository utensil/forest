import init, { start, run_program } from '../lib/egglog/web-demo/pkg';

await init();

function log(level, str) {
    // console.log(str);
}

window.log = log;

let result = run_program(`(function fib (i64) i64)
(set (fib 0) 0)
(set (fib 1) 1)

(rule ((= f0 (fib x))
       (= f1 (fib (+ x 1))))
      ((set (fib (+ x 2)) (+ f0 f1))))

(run 7)

(check (= (fib 7) 13))`);

console.log(result);
