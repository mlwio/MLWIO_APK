#!/usr/bin/env python3
import http.server
import socketserver
import os
import urllib.request
import urllib.error
from urllib.parse import urlparse, parse_qs

class ProxyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()
    
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/proxy':
            query_params = parse_qs(parsed_path.query)
            if 'url' in query_params:
                self.proxy_image(query_params['url'][0])
            else:
                self.send_error(400, 'Missing url parameter')
        else:
            super().do_GET()
    
    def proxy_image(self, url):
        try:
            req = urllib.request.Request(url)
            req.add_header('User-Agent', 'Mozilla/5.0')
            
            with urllib.request.urlopen(req, timeout=30) as response:
                content_type = response.headers.get('Content-Type', 'image/jpeg')
                data = response.read()
                
                self.send_response(200)
                self.send_header('Content-Type', content_type)
                self.send_header('Content-Length', len(data))
                self.end_headers()
                
                chunk_size = 16384
                offset = 0
                while offset < len(data):
                    try:
                        chunk = data[offset:offset + chunk_size]
                        self.wfile.write(chunk)
                        self.wfile.flush()
                        offset += chunk_size
                    except BrokenPipeError:
                        break
                    
        except urllib.error.HTTPError as e:
            try:
                self.send_error(e.code, str(e.reason))
            except BrokenPipeError:
                pass
        except Exception as e:
            print(f"Proxy error: {e}")
            try:
                self.send_error(500, str(e))
            except BrokenPipeError:
                pass

os.chdir('build/web')

PORT = 5000
Handler = ProxyHTTPRequestHandler

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Server running at http://0.0.0.0:{PORT}/")
    httpd.serve_forever()
