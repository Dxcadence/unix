#include <iostream>
#include <csignal>
#include <cstdlib>
#include <unistd.h> // для sleep()
#include <librdkafka/rdkafkacpp.h>

using namespace std;

bool running = true;

void signal_handler(int signal) {
    cout << "[Worker] Received shutdown signal..." << endl;
    running = false;
}

class ExampleConsumer : public RdKafka::EventCb {
public:
    void event_cb(RdKafka::Event &event) override {
        if (event.type() == RdKafka::Event::EVENT_ERROR)
            cerr << "Error: " << RdKafka::err2str(event.err()) << endl;
        else
            cerr << "Event: " << event.str() << endl;
    }
};

// Функция ожидания Kafka
bool wait_for_kafka(RdKafka::KafkaConsumer *consumer, int max_retries = 10, int retry_interval = 5) {
    for (int i = 0; i < max_retries; ++i) {
        RdKafka::Metadata *metadata;
        if (consumer->metadata(false, NULL, &metadata, 5000) == RdKafka::ERR_NO_ERROR) {
            cout << "[Worker] Successfully connected to Kafka." << endl;
            delete metadata;
            return true;
        } else {
            cerr << "[Worker] Waiting for Kafka... (" << i + 1 << "/" << max_retries << ")" << endl;
            sleep(retry_interval);
        }
    }

    cerr << "[Worker] Could not connect to Kafka after several retries." << endl;
    return false;
}

int main() {
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    string errstr;
    RdKafka::Conf *conf = RdKafka::Conf::create(RdKafka::Conf::CONF_GLOBAL);

    conf->set("metadata.broker.list", "kafka:9092", errstr);
    conf->set("group.id", "worker-group", errstr);
    conf->set("enable.auto.commit", "false", errstr);  // Ручное подтверждение

    ExampleConsumer ex_con;
    conf->set("event_cb", &ex_con, errstr);

    RdKafka::KafkaConsumer *consumer = RdKafka::KafkaConsumer::create(conf, errstr);
    if (!consumer) {
        cerr << "Failed to create consumer: " << errstr << endl;
        exit(1);
    }

    // Ждём, пока Kafka будет доступна
    if (!wait_for_kafka(consumer)) {
        cerr << "[Worker] Kafka is unreachable. Exiting..." << endl;
        delete consumer;
        return 1;
    }

    // Подписываемся на топик после успешного подключения
    consumer->subscribe({ "tasks" });

    while (running) {
        RdKafka::Message *msg = consumer->consume(1000);
        switch (msg->err()) {
            case RdKafka::ERR__TIMED_OUT:
                break;

            case RdKafka::ERR_NO_ERROR:
                cout << "[Worker] Received message: "
                     << string(static_cast<char*>(msg->payload()), msg->len())
                     << endl;

                // Имитация долгой работы — например, 10 секунд
                cout << "[Worker] Simulating long work (10s)..." << endl;
                sleep(10);  // Долгая работа

                // Зафиксируем обработку только после выполнения
                {
                    RdKafka::ErrorCode err_code = consumer->commitSync(msg);
                    if (err_code != RdKafka::ERR_NO_ERROR) {
                        cerr << "Commit failed: " << RdKafka::err2str(err_code) << endl;
                    } else {
                        cout << "[Worker] Message processed and committed." << endl;
                    }
                }
                break;

            default:
                cerr << "Consume error: " << msg->errstr() << endl;
                break;
        }
        delete msg;
    }

    delete consumer;
    return 0;
}