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
	.ws('/live', {
		async open(ws) {
            // ws.subscribe('update')
            all_ws.push(ws)
            // set a limit of 20 connections for now, enough for my local development
            if(all_ws.length > 20) {
                console.log(`Too many connections: ${all_ws.length}`)
                while (all_ws.length > 20) {
                    const ws_to_close = all_ws.shift()
                    ws_to_close?.close()
                }
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
        let lastSentFile
        for await (const event of watcher) {
            // debounce
            if (Date.now() - lastSent < 1000) {
                continue
            }

            // console.log('event:', event)

            if(event.eventType == 'change' && event.filename == 'trigger.txt') {

                const updated_file = Bun.file('build/live/updated_file.txt')

                if (await updated_file.exists()) {
                    const updated_file_name = await updated_file.text()

                    // same file debounce
                    if (updated_file_name == lastSentFile && Date.now() - lastSent < 5000) {
                        continue
                    }

                    for (const ws of all_ws) {
                        ws.send({
                            type: 'update',
                            data: updated_file_name
                        })
                    }

                    lastSent = Date.now()
                    lastSentFile = updated_file_name
                }
            }
        }
    })