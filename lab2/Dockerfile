FROM alpine:latest

RUN apk add --no-cache bash coreutils

WORKDIR /app

COPY concurrent.sh /app/concurrent.sh

RUN chmod +x /app/concurrent.sh

CMD ["sh", "./concurrent.sh"]
