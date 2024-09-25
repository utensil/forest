const saveScrollPosition = () => {
    sessionStorage.setItem(
        window.location.href,
        JSON.stringify({
            x: window.scrollX,
            y: window.scrollY,
        }),
    )
    // console.debug('saved scroll position:', window.scrollX, window.scrollY);
}

const reloadWithScroll = () => {
    saveScrollPosition()
    window.location.reload()
}

const startLiveReload = () => {
    const hostname = window.location.hostname
    const port = window.location.port

    const ws = new WebSocket(`ws://${hostname}:${port}/live`)
    ws.onopen = () => {
        console.debug('live reload connected')
        // const intervalID = setInterval(function() {
        //     if (ws.readyState === WebSocket.OPEN) {
        //         ws.send('ping');
        //     } else {
        //         clearInterval(intervalID);
        //     }
        // }, 10*60*1000);
    }
    ws.onerror = (event) => {
        console.error('live reload error:', event)
    }
    ws.onmessage = (event) => {
        // console.log(event);
        const message = JSON.parse(event.data)
        if (message.type === 'update') {
            console.debug('reloading for:', message.data)
            ws.onclose = null
            ws.close()
            // trim messgae.data
            message.data = message.data.trim()
            if (/\.tree$/.test(message.data)) {
                const path_parts = message.data.split('/')
                let page = path_parts.pop() || window.location.pathname
                page = page.replace(/\.tree$/, '.xml')
                page = `/${page}`
                console.debug(window.location.pathname, page)
                if (window.location.pathname !== page) {
                    console.debug(`redirecting to ${page}`)
                    window.location.replace(page)
                } else {
                    console.debug('reloading current page')
                    reloadWithScroll()
                }
            } else {
                console.debug('reloading current page')
                reloadWithScroll()
            }
        } else {
            console.debug('recv:', event)
        }
    }
    ws.onclose = () => {
        console.debug('live reload disconnected')
        setTimeout(startLiveReload, 1000 * Math.random())
    }
}

window.addEventListener('load', () => {
    const scrollPosition = JSON.parse(
        sessionStorage.getItem(window.location.href),
    )
    // console.debug('scroll position:', scrollPosition);
    if (scrollPosition) {
        window.scrollTo(scrollPosition.x, scrollPosition.y)
        sessionStorage.removeItem(window.location.href)
    }
})

startLiveReload()
