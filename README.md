# MiroTalk

A JavaScript-based project for real-time communication and collaboration.

> [!NOTE]
> The original source code was patched to remove advertisements, sponsored links, stats tracking, and other.

To run the project, simply execute the following command:

```shell
docker run --rm \
  -p 3000:3000/tcp \
  -e "JWT_KEY=your_secret" \
  -e "API_KEY_SECRET=your_api_secret" \
    ghcr.io/iddqd-uk/mirotalk:latest
```

And navigate to `http://localhost:3000` in your web browser.
