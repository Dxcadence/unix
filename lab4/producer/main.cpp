#include <iostream>
#include <string>
#include <librdkafka/rdkafkacpp.h>

int main(int argc, char *argv[]) {
    RdKafka::Conf *conf = RdKafka::Conf::create(RdKafka::Conf::CONF_GLOBAL);
    std::string errstr;

    conf->set("metadata.broker.list", "kafka:9092", errstr);
    RdKafka::Producer *producer = RdKafka::Producer::create(conf, errstr);
    if (!producer) {
        std::cerr << "Failed to create producer: " << errstr << std::endl;
        return 1;
    }

    RdKafka::Topic *topic = RdKafka::Topic::create(producer, "tasks", NULL, errstr);
    if (!topic) {
        std::cerr << "Failed to create topic object: " << errstr << std::endl;
        return 1;
    }

    for (int i = 0; i < 5; ++i) {
        std::string payload = R"({"id":)" + std::to_string(i) + "}";
        RdKafka::ErrorCode resp = producer->produce(
            topic,
            RdKafka::Topic::PARTITION_UA,
            RdKafka::Producer::RK_MSG_COPY,
            const_cast<void*>(static_cast<const void*>(payload.c_str())),
            payload.size(),
            NULL,
            NULL
        );

        if (resp != RdKafka::ERR_NO_ERROR)
            std::cerr << "Produce failed: " << RdKafka::err2str(resp) << std::endl;

        producer->poll(0);
    }

    producer->flush(10000);
    delete topic;
    delete producer;

    return 0;
}