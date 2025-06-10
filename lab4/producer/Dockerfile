FROM gcc:11

RUN apt-get update && \
    apt-get install -y librdkafka-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN g++ -std=c++17 main.cpp -o producer -lrdkafka++ -I/usr/include/librdkafka
CMD ["./producer"]