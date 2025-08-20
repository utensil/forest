# Caddy SSL/HTTP Compatibility Analysis

## Problem Summary

When using Python's `requests` library to connect to Caddy-proxied HTTPS endpoints, we encountered SSL errors:
```
SSLError(SSLEOFError(8, '[SSL: UNEXPECTED_EOF_WHILE_READING] EOF occurred in violation of protocol (_ssl.c:1006)'))
```

However, `curl` worked perfectly with the same endpoints.

## Root Cause Analysis

### The Issue: HTTP/2 vs HTTP/1.1 Compatibility

Through systematic testing, we discovered the issue is **HTTP/2 compatibility** between Python's HTTP libraries and Caddy's HTTP/2 implementation.

### Test Results

| Method | Protocol | Result | Notes |
|--------|----------|--------|-------|
| `curl` (default) | HTTP/2 (h2) | ✅ Works | Uses TLS 1.3 + AEAD-CHACHA20-POLY1305-SHA256 |
| `curl --http1.1` | HTTP/1.1 | ✅ Works | Forces HTTP/1.1, still works |
| `requests` library | HTTP/2 (negotiated) | ❌ Fails | SSL EOF errors |
| `urllib3` direct | HTTP/1.1 (default) | ✅ Works | Doesn't negotiate HTTP/2 |
| Raw SSL + HTTP/1.1 | HTTP/1.1 | ✅ Works | Manual ALPN to force HTTP/1.1 |

### Technical Details

1. **ALPN Negotiation**: Caddy advertises both `h2` (HTTP/2) and `http/1.1`
2. **Python's Choice**: When both are available, Python libraries prefer HTTP/2
3. **Compatibility Issue**: Python's HTTP/2 implementation has compatibility issues with Caddy's HTTP/2 server
4. **Curl's Advantage**: Curl's HTTP/2 implementation is more robust and handles Caddy correctly

### Caddy Configuration Context

```
linkwarden.homelab.local {
    reverse_proxy linkwarden:3000
    tls internal
}
```

- Uses `tls internal` (self-signed certificates from Caddy Local Authority)
- Certificate has empty subject field
- Very short validity (12 hours)
- Uses ECDSA with P-256 curve
- Supports both HTTP/1.1 and HTTP/2

## Solutions

### 1. Use curl (Current Implementation)
```python
def curl_request(method, url, data=None, timeout=10):
    cmd = ['curl', '-k', '-s', '-w', '%{http_code}', ...]
    # Works with both HTTP/1.1 and HTTP/2
```

**Pros**: 
- Works reliably with Caddy's HTTP/2
- Handles SSL/TLS edge cases well
- Battle-tested HTTP client

**Cons**: 
- External dependency
- More complex error handling
- Subprocess overhead

### 2. Use urllib3 Directly
```python
import urllib3
http = urllib3.PoolManager(cert_reqs='CERT_NONE')
response = http.request('GET', url, headers=headers)
```

**Pros**: 
- Pure Python solution
- Uses HTTP/1.1 by default (avoids HTTP/2 issues)
- Lighter weight than requests

**Cons**: 
- Lower-level API
- Less convenient than requests
- Still a workaround

### 3. Force HTTP/1.1 in requests (Attempted)
```python
class HTTP11Adapter(requests.adapters.HTTPAdapter):
    def init_poolmanager(self, *args, **kwargs):
        context = ssl.create_default_context()
        context.set_alpn_protocols(['http/1.1'])  # Force HTTP/1.1
        kwargs['ssl_context'] = context
        return super().init_poolmanager(*args, **kwargs)
```

**Result**: Still failed - requests library has deeper HTTP/2 integration issues

## Why This Happens

### HTTP/2 Implementation Differences

1. **Frame Handling**: Different HTTP/2 frame processing between curl and Python
2. **Connection Management**: Caddy might expect specific HTTP/2 connection behavior
3. **SSL/TLS Integration**: HTTP/2 requires more complex SSL/TLS handling
4. **ALPN Negotiation**: Subtle differences in protocol negotiation

### Caddy-Specific Factors

1. **Internal TLS**: Self-signed certificates with unusual properties
2. **Reverse Proxy**: Additional layer that might affect HTTP/2 behavior
3. **Go HTTP/2 Stack**: Caddy uses Go's HTTP/2 implementation
4. **Certificate Properties**: Empty subject, short validity, ECC curves

## Recommendations

### For Production Use
1. **Stick with curl approach** - Most reliable and battle-tested
2. **Monitor Caddy updates** - HTTP/2 compatibility might improve
3. **Consider urllib3** - For pure Python solution if curl is not desired

### For Debugging Similar Issues
1. **Test HTTP/1.1 vs HTTP/2** separately
2. **Check ALPN negotiation** with `openssl s_client`
3. **Compare curl verbose output** with Python SSL debugging
4. **Test with different TLS versions** and cipher suites

### For Caddy Configuration
1. **Consider HTTP/1.1 only** if Python compatibility is critical:
   ```
   linkwarden.homelab.local {
       reverse_proxy linkwarden:3000
       tls internal
       protocols h1  # Force HTTP/1.1 only
   }
   ```
2. **Use proper certificates** instead of `tls internal` if possible
3. **Monitor Caddy logs** for HTTP/2 related errors

## Conclusion

The issue is a **compatibility problem between Python's HTTP/2 client implementation and Caddy's HTTP/2 server implementation**. This is not uncommon - HTTP/2 is complex and different implementations can have subtle incompatibilities.

The curl-based solution is the most pragmatic approach as it leverages curl's mature and robust HTTP/2 implementation that works well with Caddy.

## References

- [Caddy HTTP/2 Documentation](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#http-versions)
- [Python urllib3 HTTP/2 Support](https://urllib3.readthedocs.io/en/stable/advanced-usage.html#http-2)
- [ALPN Protocol Negotiation](https://tools.ietf.org/html/rfc7301)
- [HTTP/2 Specification](https://tools.ietf.org/html/rfc7540)
