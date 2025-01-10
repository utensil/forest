// bun add elysia @elysiajs/static @types/bun
import { watch } from 'node:fs/promises'
import { mkdir } from 'node:fs/promises'
import { staticPlugin } from '@elysiajs/static'
import { Elysia } from 'elysia'

const port = process.env.PORT || 3000

const app = new Elysia({
    websocket: {
        idleTimeout: 960,
    },
})
    // .get('/', ({ redirect }) => {
    //     return redirect('/index.xml')
    // })
    .use(
        staticPlugin({
            assets: 'output',
            prefix: '',
        }),
    )
    .ws('/live', {
        async open(ws) {
            ws.subscribe('update')
        },
        async close(ws) {
            ws.unsubscribe('update')
        },
    })

app.listen(port, async ({ hostname, port }) => {
    console.log(`Serving: http://${hostname}:${port}/`)

    // console.log(app.server?.publish)
    await mkdir('build/live/', { recursive: true })

    const watcher = watch('build/live/')
    let lastSent = Date.now()
    let lastSentFile: string
    for await (const event of watcher) {
        // // debounce
        // if (Date.now() - lastSent < 2000) {
        //     continue
        // }

        // console.log('event:', event)

        if (event.eventType === 'change' && event.filename === 'trigger.txt') {
            const updated_file = Bun.file('build/live/updated_file.txt')

            if (await updated_file.exists()) {
                const updated_file_name = await updated_file.text()

                // same file debounce
                // if (updated_file_name == lastSentFile && Date.now() - lastSent < 3000) {
                //     continue
                // }

                // postpone to debounce
                setTimeout(() => {
                    console.log('🔥live reload:', updated_file_name.trim())
                    app.server?.publish(
                        'update',
                        JSON.stringify({
                            type: 'update',
                            data: updated_file_name.trim(),
                        }),
                    )
                    lastSent = Date.now()
                    lastSentFile = updated_file_name
                    console.log(`Serving: http://${hostname}:${port}/`)
                }, 10)
            }
        }
    }
})
