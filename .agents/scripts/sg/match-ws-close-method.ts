// Example match for match-ws-close-method (TypeScript)
app.ws('/live', {
  async close(ws) {
    ws.terminate();
  },
  open(ws) {
    // not matched
  }
});
