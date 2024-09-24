// bun add elysia @elysiajs/static @types/bun
import { Elysia } from 'elysia'
import { staticPlugin } from '@elysiajs/static'
import { watch } from "fs/promises";

const port = process.env.PORT || 3000

let all_ws : any[] = []

new Elysia()
    .use(staticPlugin({
        assets: 'output',
        prefix: ''
    }))
	// .get('/', 'Hello World')
	// .get('/image', Bun.file('mika.webp'))
	// .get('/stream', function* () {
	// 	yield 'Hello'
	// 	yield 'World'
	// })
	// .get('/ok', function* () {
	// 	yield 1
	// 	yield 2
	// 	yield 3
	// })
	.ws('/live', {
		async open(ws) {
            all_ws.push(ws)
            // set a limit of 20 connections for now, enough for my local development
            while (all_ws.length > 20) {
                const ws_to_close = all_ws.shift()
                ws_to_close.close()
            }
        },
        async close(ws) {
            all_ws = all_ws.filter((w) => w !== ws)
        }
	})
	.listen(port, async ({ hostname, port }) => {
        console.log(`Serving: http://${hostname}:${port}/index.xml`)

        const watcher = watch('build/live/')
        let lastSent = Date.now()
        for await (const event of watcher) {
            if (Date.now() - lastSent < 1000) {
                continue
            }

            console.log('event:', event)

            if(event.eventType == 'change' && event.filename == 'trigger.txt') {

                const updated_file = Bun.file('build/live/updated_file.txt')

                if (await updated_file.exists()) {
                    const updated_file_name = await updated_file.text()
                    for (const ws of all_ws) {
                        ws.send({
                            type: 'update',
                            data: updated_file_name
                        })
                    }
                    lastSent = Date.now()
                }
            }
        }
    })