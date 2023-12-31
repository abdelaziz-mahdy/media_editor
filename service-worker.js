self.addEventListener('fetch', function(event) {
    event.respondWith(
      fetch(event.request).then(function(response) {
        const modifiedHeaders = new Headers(response.headers);
        modifiedHeaders.set('Cross-Origin-Embedder-Policy', 'require-corp');
        modifiedHeaders.set('Cross-Origin-Opener-Policy', 'same-origin');
  
        const modifiedResponse = new Response(response.body, {
          status: response.status,
          statusText: response.statusText,
          headers: modifiedHeaders
        });
  
        return modifiedResponse;
      })
    );
  });
  