const hostname = window.location.hostname;
const port = window.location.port;

const ws = new WebSocket(`ws://${hostname}:${port}/live`);
ws.onopen = function() {
    console.debug('live reload connected');
};
ws.onerror = function(event) {
    console.error('live reload error:', event);
};
ws.onmessage = function(event) {
    const message = JSON.parse(event.data);
    if (message.type === 'update') {
        console.debug('reloading for ' + message.data);
        ws.onclose = null;
        ws.close();
        window.location.reload();
    }
};
ws.onclose = function() {
    console.debug('live reload disconnected');
};