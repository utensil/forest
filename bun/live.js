const startLiveReload = () => {

    const hostname = window.location.hostname;
    const port = window.location.port;

    const ws = new WebSocket(`ws://${hostname}:${port}/live`);
    ws.onopen = function() {
        console.debug('live reload connected');
        const intervalID = setInterval(function() {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send('ping');
            } else {
                clearInterval(intervalID);
            }
        }, 10*60*1000);
    };
    ws.onerror = function(event) {
        console.error('live reload error:', event);
    };
    ws.onmessage = function(event) {
        const message = JSON.parse(event.data);
        if (message.type === 'update') {
            console.debug('reloading for:', message.data);
            ws.onclose = null;
            ws.close();
            // trim messgae.data
            message.data = message.data.trim();
            if (/\.tree$/.test(message.data)) {
                let path_parts = message.data.split('/');
                let page = path_parts.pop() || window.location.pathname;
                page = page.replace(/\.tree$/, '.xml');
                console.debug(`navigate to ${page}`);
                window.location.replace(`/${page}`);
            } else {
                console.debug('reloading current page');
                window.location.reload();
            } 
        } else {
            console.debug('recv:', event);
        }
    };
    ws.onclose = function() {
        console.debug('live reload disconnected');
        setTimeout(startLiveReload, 1000 * Math.random());
    };
}

startLiveReload();