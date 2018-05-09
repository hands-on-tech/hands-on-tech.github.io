---
layout: post
title:  "Kafka streaming with Spark and Flink"
subtitle:  "Example project running on top of Docker with one producer sending words and three different consumers counting the occurrences of each word."
date:   2018-05-05 00:00:00 +0100
author: David Campos
tags: java kafka spark flink docker docker-compose
comments: true
read_time: true
background: '/assets/kafka-spark-flink-example/background.jpg'
---

# TL;DR
Example project taking advantage of Kafka messages streaming communication platform using:
- 1 data producer sending random numbers in textual format;
- 3 different data consumers using Kafka, Spark and Flink to count numbers occurrences.

Source code is available on [Github](https://github.com/davidcampos/kafka-spark-flink-example){:target="_blank"} with detailed documentation on how to build and run the different software components using Docker.

# Introduction

## Kafka
[Kafka](https://kafka.apache.org) is becoming the *de-facto* standard messaging platform, enabling large-scale communication between software components producing and consuming streams of data for different purposes. It was originally built at LinkedIn and is currently part of the Apache Software Foundation. By using Kafka, one can implement solutions for:
- Publish and subscribe: 
- React to events:
- Data streaming:

![Kafka](/assets/kafka-spark-flink-example/kafka.png){: .image-center}
***Figure:** Illustration of Kafka capabilities as a message broker between heterogeneous producers and consumers. Source [https://kafka.apache.org](https://kafka.apache.org).*

[Hundreds of companies](https://cwiki.apache.org/confluence/display/KAFKA/Powered+By){:target="_blank"} already take advantage of Kafka to provide their services, such as Oracle, LinkedIn (obviously), Mozilla and Netflix. As a result, it is being used in may different real-life use cases.


For instance, in the IoT context, we can have thousands of devices sending streams of operational data to Kafka, which are then processed and stored for many different purposes. In that context, taking advantage of streaming one can react on real-time to some changes on IoT connected devices.


Steve Wilkes provides a more detailed analyses of some real world application examples of Kafka. Please check the article on [LinkedIn](https://www.linkedin.com/pulse/make-most-kafka-real-world-steve-wilkes/){:target="_blank"}.


Kafka in Financing analysis
https://www.confluent.io/blog/real-time-financial-alerts-rabobank-apache-kafkas-streams-api/


Kafka Summit San Francisco
https://www.confluent.io/kafka-summit-sf17/resource/

## Spark

[Spark](https://spark.apache.org){:target="_blank"}

## Flink
When considering real-time data processing and timeseries 

[Flink](https://flink.apache.org){:target="_blank"}

# Goal
- Send words to message broker
- Consumers should receive messages and count number of words sent

# Architecture

![Architecture](/assets/kafka-spark-flink-example/architecture.svg){: .image-center}
***Figure:** Illustration of the implementation architecture of the example project.*


# Requirements
In order to achieve he aforementioned goals, the following technologies were used:
- Java 8 as main programming language for producer and consumers. Actually tried to use Java 10 first, but had several problems with Spark and Flink Scala versions.
- Maven:
- Docker: containerization
- Docker Compose:

# Kafka Server
Before putting our hands on code, we need to have a Kafka server running, in order to develop and test our code.

Create bridge network communicate between containers


Set network alias of the container to access it.
```docker
version: '3.6'

networks:
  bridge:
    driver: bridge

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 32181
      ZOOKEEPER_TICK_TIME: 2000
    networks:
      bridge:
        aliases:
          - zookeeper

  kafka:
    image: wurstmeister/kafka:latest
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ADVERTISED_HOST_NAME: 0.0.0.0
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:32181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      JMX_PORT: 9999
    networks:
      bridge:
        aliases:
          - kafka
  
  kafka-manager:
    image: sheepkiller/kafka-manager:latest
    environment:
      ZK_HOSTS: "zookeeper:32181"
    ports:
      - 9000:9000
    networks:
      - bridge
```
***Code:** `docker-compose.yml` file for running Zookeeper, Kafka and Kafka Manager.*

Go to [http://localhost:9000](http://localhost:9000) to access the Kafka Manager.

![Kafka Manager](/assets/kafka-spark-flink-example/kafka-manager.png){: .image-center .img-thumbnail}
***Figure:** Kafka Manager interface to manage a topic and get operation feedback.*

# Configurations
```java
public final static String EXAMPLE_KAFKA_TOPIC = System.getenv("EXAMPLE_KAFKA_TOPIC") != null ?
        System.getenv("EXAMPLE_KAFKA_TOPIC") : "example";
public final static String EXAMPLE_KAFKA_SERVER = System.getenv("EXAMPLE_KAFKA_SERVER") != null ?
        System.getenv("EXAMPLE_KAFKA_SERVER") : "localhost:9092";
public final static String EXAMPLE_ZOOKEEPER_SERVER = System.getenv("EXAMPLE_ZOOKEEPER_SERVER") != null ?
        System.getenv("EXAMPLE_ZOOKEEPER_SERVER") : "localhost:32181";
```
***Code:** Maven dependency to create a Kafka topic using the Zookeeper client.*

# Topic
```xml
<!-- Zookeeper -->
<dependency>
    <groupId>com.101tec</groupId>
    <artifactId>zkclient</artifactId>
    <version>0.10</version>
</dependency>
```
***Code:** Maven dependency to create a Kafka topic using the Zookeeper client.*

For this example, only 1 partition will be created. Such topic might be explorer later.


```java
private static void createTopic() {
    int sessionTimeoutMs = 10 * 1000;
    int connectionTimeoutMs = 8 * 1000;

    ZkClient zkClient = new ZkClient(
            Commons.EXAMPLE_ZOOKEEPER_SERVER,
            sessionTimeoutMs,
            connectionTimeoutMs,
            ZKStringSerializer$.MODULE$);

    boolean isSecureKafkaCluster = false;
    ZkUtils zkUtils = new ZkUtils(zkClient, new ZkConnection(Commons.EXAMPLE_ZOOKEEPER_SERVER), isSecureKafkaCluster);

    int partitions = 1;
    int replication = 1;

    // Add topic configuration here
    Properties topicConfig = new Properties();
    if (!AdminUtils.topicExists(zkUtils, Commons.EXAMPLE_KAFKA_TOPIC)) {
        AdminUtils.createTopic(zkUtils, Commons.EXAMPLE_KAFKA_TOPIC, partitions, replication, topicConfig, RackAwareMode.Safe$.MODULE$);
        logger.info("Topic {} created.", Commons.EXAMPLE_KAFKA_TOPIC);
    } else {
        logger.info("Topic {} already exists.", Commons.EXAMPLE_KAFKA_TOPIC);
    }

    zkClient.close();
}
```
***Code:** Connect to Zookeeper and create the Kafka topic if it does not exist yet.*

# Producer

```xml
<!-- Kafka -->
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka-clients</artifactId>
    <version>1.1.0</version>
</dependency>
```
***Code:** Maven dependency to create a Kafka Producer.*

`StringSerializer`

```java
private static Producer<String, String> createProducer() {
    Properties props = new Properties();
    props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, Commons.EXAMPLE_KAFKA_SERVER);
    props.put(ProducerConfig.CLIENT_ID_CONFIG, "KafkaProducerExample");
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
    return new KafkaProducer<>(props);
}
```
***Code:** Create a Kafka Producer.*

`EXAMPLE_PRODUCER_INTERVAL`

```java
public static void main(final String... args) {
    // Create topic
    createTopic();

    String[] words = new String[]{"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"};
    Random ran = new Random(System.currentTimeMillis());

    final Producer<String, String> producer = createProducer();
    int EXAMPLE_PRODUCER_INTERVAL = System.getenv("EXAMPLE_PRODUCER_INTERVAL") != null ?
            Integer.parseInt(System.getenv("EXAMPLE_PRODUCER_INTERVAL")) : 100;

    try {
        while (true) {
            String word = words[ran.nextInt(words.length)];
            String uuid = UUID.randomUUID().toString();

            ProducerRecord<String, String> record = new ProducerRecord<>(Commons.EXAMPLE_KAFKA_TOPIC, uuid, word);
            RecordMetadata metadata = producer.send(record).get();

            logger.info("Sent ({}, {}) to topic {} @ {}.", uuid, word, Commons.EXAMPLE_KAFKA_TOPIC, metadata.timestamp());

            Thread.sleep(EXAMPLE_PRODUCER_INTERVAL);
        }
    } catch (InterruptedException | ExecutionException e) {
        logger.error("An error occurred.", e);
    } finally {
        producer.flush();
        producer.close();
    }
}
```
***Code:** Send a random word to Kafka every 100ms (default value).*

# Consumers
In this example, each consumer has its specific group associated, which means that **all messages will be delivered to all groups, and consequently to each consumer**.
When a topic has multiple partitions and we have multiple consumers in the same group, each consumer should read messages from different partitions, since it is **not allowed to have multiple consumers reading messages from the same partition**. This means that running multiple containers for the same consumer and consumer group will result in only one consumer receiving the messages. For instance, if we run 3 containers for the Kafka consumer, only one of them will receive the messages.

![Consumers](/assets/kafka-spark-flink-example/consumers.svg){: .image-center}
***Figure:** Illustration of the topic partition and relation with consumer groups and respective consumers.*


# Kafka Consumer

```java
private static Consumer<String, String> createConsumer() {
    // Create properties
    final Properties props = new Properties();
    props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, Commons.EXAMPLE_KAFKA_SERVER);
    props.put(ConsumerConfig.GROUP_ID_CONFIG, "KafkaConsumerGroup");
    props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
    props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());

    // Create the consumer using properties
    final Consumer<String, String> consumer = new KafkaConsumer(props);

    // Subscribe to the topic.
    consumer.subscribe(Collections.singletonList(Commons.EXAMPLE_KAFKA_TOPIC));
    return consumer;
}
```
***Code:** Create Kafka consumer subscribing to topic.*

```java
public static void main(final String... args) {
    final Consumer<String, String> consumer = createConsumer();

    while (true) {
        final ConsumerRecords<String, String> consumerRecords = consumer.poll(1000);
        consumerRecords.forEach(record -> {
            logger.info("Consumer Record:({}, {}, {}, {})", record.key(), record.value(), record.partition(), record.offset());
        });
        consumer.commitAsync();
    }
}
```
***Code:** Polling 1000 records from the Kafka topic.*


# Spark Stream Consumer

```xml
<!--Spark-->
<dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-streaming_2.11</artifactId>
    <version>2.3.0</version>
</dependency>
<dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-streaming-kafka-0-10_2.11</artifactId>
    <version>2.3.0</version>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.module</groupId>
    <artifactId>jackson-module-scala_2.11</artifactId>
    <version>2.9.5</version>
</dependency>
```
***Code:** Maven dependencies to create a Spark Consumer.*

```java
public static void main(final String... args) {
    // Configure Spark to connect to Kafka running on local machine
    Map<String, Object> kafkaParams = new HashMap<>();
    kafkaParams.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, Commons.EXAMPLE_KAFKA_SERVER);
    kafkaParams.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
    kafkaParams.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
    kafkaParams.put(ConsumerConfig.GROUP_ID_CONFIG, "SparkConsumerGroup");

    //Configure Spark to listen messages in topic test
    Collection<String> topics = Arrays.asList(Commons.EXAMPLE_KAFKA_TOPIC);

    SparkConf conf = new SparkConf().setMaster("local[2]").setAppName("SparkConsumerApplication");

    //Read messages in batch of 5 seconds
    JavaStreamingContext jssc = new JavaStreamingContext(conf, Durations.seconds(5));

    // Start reading messages from Kafka and get DStream
    final JavaInputDStream<ConsumerRecord<String, String>> stream =
            KafkaUtils.createDirectStream(jssc, LocationStrategies.PreferConsistent(),
                    ConsumerStrategies.Subscribe(topics, kafkaParams));

    // Read value of each message from Kafka and return it
    JavaDStream<String> lines = stream.map((Function<ConsumerRecord<String, String>, String>) kafkaRecord -> kafkaRecord.value());

    // Break every message into words and return list of words
    JavaDStream<String> words = lines.flatMap((FlatMapFunction<String, String>) line -> Arrays.asList(line.split(" ")).iterator());

    // Take every word and return Tuple with (word,1)
    JavaPairDStream<String, Integer> wordMap = words.mapToPair((PairFunction<String, String, Integer>) word -> new Tuple2<>(word, 1));

    // Count occurrence of each word
    JavaPairDStream<String, Integer> wordCount = wordMap.reduceByKey((Function2<Integer, Integer, Integer>) (first, second) -> first + second);

    //Print the word count
    wordCount.print();

    jssc.start();
    try {
        jssc.awaitTermination();
    } catch (InterruptedException e) {
        logger.error("An error occurred.", e);
    }
}
```
***Code:** Spark stream consumer to count words occurrences from last 5s.*

# Flink Stream Consumer

```xml
<!--Flink-->
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-java</artifactId>
    <version>1.4.2</version>
</dependency>
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-streaming-java_2.11</artifactId>
    <version>1.4.2</version>
</dependency>
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-clients_2.11</artifactId>
    <version>1.4.2</version>
</dependency>
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-connector-kafka-0.10_2.11</artifactId>
    <version>1.4.2</version>
</dependency>
```
***Code:** Maven dependencies to create a Flink Consumer.*

```java
public static final class Tokenizer implements FlatMapFunction<String, Tuple2<String, Integer>> {
    @Override
    public void flatMap(String value, Collector<Tuple2<String, Integer>> out) {
        // normalize and split the line
        String[] tokens = value.toLowerCase().split("\\W+");

        // emit the pairs
        for (String token : tokens) {
            if (token.length() > 0) {
                out.collect(new Tuple2<>(token, 1));
            }
        }
    }
}
```
***Code:** Tokenizer to split messages into word tokens and return a pair `<word, 1>`.*

```java
public static void main(final String... args) {
    // Create execution environment
    StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

    // Properties
    final Properties props = new Properties();
    props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, Commons.EXAMPLE_KAFKA_SERVER);
    props.put(ConsumerConfig.GROUP_ID_CONFIG, "FlinkConsumerGroup");

    DataStream<String> messageStream = env.addSource(new FlinkKafkaConsumer010<>(Commons.EXAMPLE_KAFKA_TOPIC, new SimpleStringSchema(), props));


    // Split up the lines in pairs (2-tuples) containing: (word,1)
    messageStream.flatMap(new Tokenizer())
            // group by the tuple field "0" and sum up tuple field "1"
            .keyBy(0)
            .sum(1)
            .print();

    try {
        env.execute();
    } catch (Exception e) {
        logger.error("An error occurred.", e);
    }
}
```
***Code:** Setup Flink to continuously consume messages and count and print occurrences per word.*

# Main
Environment variable `EXAMPLE_GOAL` is used to get the goal of the program, i.e., to run a producer of a consumer with kafka, spark or flink.

```java
public static void main(final String... args) {
    String EXAMPLE_GOAL = System.getenv("EXAMPLE_GOAL") != null ?
            System.getenv("EXAMPLE_GOAL") : "producer";

    logger.info("Kafka Topic: {}", Commons.EXAMPLE_KAFKA_TOPIC);
    logger.info("Kafka Server: {}", Commons.EXAMPLE_KAFKA_SERVER);
    logger.info("Zookeeper Server: {}", Commons.EXAMPLE_ZOOKEEPER_SERVER);
    logger.info("GOAL: {}", EXAMPLE_GOAL);

    switch (EXAMPLE_GOAL.toLowerCase()) {
        case "producer":
            KafkaProducerExample.main();
            break;
        case "consumer.kafka":
            KafkaConsumerExample.main();
            break;
        case "consumer.spark":
            KafkaSparkConsumerExample.main();
            break;
        case "consumer.flink":
            KafkaFlinkConsumerExample.main();
            break;
        default:
            logger.error("No valid goal to run.");
            break;
    }
}
```
***Code:** Main program to select which program to run.*

# Build package

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-shade-plugin</artifactId>
            <version>3.1.1</version>
            <executions>
                <execution>
                    <phase>package</phase>
                    <goals>
                        <goal>shade</goal>
                    </goals>
                    <configuration>
                        <filters>
                            <filter>
                                <artifact>*:*</artifact>
                                <excludes>
                                    <exclude>META-INF/*.SF</exclude>
                                    <exclude>META-INF/*.DSA</exclude>
                                    <exclude>META-INF/*.RSA</exclude>
                                </excludes>
                            </filter>
                        </filters>
                        <shadedArtifactAttached>true</shadedArtifactAttached>
                        <shadedClassifierName>jar-with-dependencies</shadedClassifierName>
                        <artifactSet>
                            <includes>
                                <include>*:*</include>
                            </includes>
                        </artifactSet>
                        <transformers>
                            <transformer
                                    implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
                                <resource>reference.conf</resource>
                            </transformer>
                            <transformer
                                    implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                                <manifestEntries>
                                    <Main-Class>org.davidcampos.kafka.cli.Main</Main-Class>
                                </manifestEntries>
                            </transformer>
                        </transformers>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

Flink does not like maven assembly plugin: TODO
Show error.

Build java package:
```shell
mvn clean package
```

# Dockerfile

```docker
FROM openjdk:8u151-jdk-alpine3.7
MAINTAINER David Campos (david.marques.campos@gmail.com)

# Install Bash
RUN apk add --no-cache bash

# Copy resources
WORKDIR /
COPY wait-for-it.sh wait-for-it.sh
COPY target/kafka-spark-flink-example-1.0-SNAPSHOT-jar-with-dependencies.jar kafka-spark-flink-example.jar

# Wait for Zookeeper and Kafka to be available and run application
CMD ./wait-for-it.sh -s -t 30 $EXAMPLE_ZOOKEEPER_SERVER -- ./wait-for-it.sh -s -t 30 $EXAMPLE_KAFKA_SERVER -- java -Xmx512m -jar kafka-spark-flink-example.jar
```
***Code:** Dockerfile for building Docker image.*

`wait-for-it.sh` is to used to check if a specific host and port is available and only run the provided command when connectivity is established.
`wait-for-it.sh` was developed by [Giles Hall](https://github.com/vishnubob) and is available at
[https://github.com/vishnubob/wait-for-it](https://github.com/vishnubob/wait-for-it).

In this case, producer and consumers should only be started when kafka is successfully running with connectivity available.

# Build Docker image

Build docker image to run producer and consumers:
```shell
docker build -t kafka-spark-flink-example .
```

Check on docker images if it is available:
```shell
docker images
```

Output:
```shell
REPOSITORY                  TAG                   IMAGE ID            CREATED             SIZE
kafka-spark-flink-example   latest                3bd70969dacd        4 days ago          253MB
```

# Docker compose


```docker
kafka-producer:
    image: kafka-spark-flink-example
    depends_on:
      - kafka
    environment:
      EXAMPLE_GOAL: "producer"
      EXAMPLE_KAFKA_TOPIC: "example"
      EXAMPLE_KAFKA_SERVER: "kafka:9092"
      EXAMPLE_ZOOKEEPER_SERVER: "zookeeper:32181"
    networks:
      - bridge
```

```docker
  kafka-consumer-kafka:
      image: kafka-spark-flink-example
      depends_on:
        - kafka-producer
      environment:
        EXAMPLE_GOAL: "consumer.kafka"
        EXAMPLE_KAFKA_TOPIC: "example"
        EXAMPLE_KAFKA_SERVER: "kafka:9092"
        EXAMPLE_ZOOKEEPER_SERVER: "zookeeper:32181"
      networks:
        - bridge
```

```docker
  kafka-consumer-spark:
        image: kafka-spark-flink-example
        depends_on:
          - kafka-producer
        ports:
          - 4040:4040
        environment:
          EXAMPLE_GOAL: "consumer.spark"
          EXAMPLE_KAFKA_TOPIC: "example"
          EXAMPLE_KAFKA_SERVER: "kafka:9092"
          EXAMPLE_ZOOKEEPER_SERVER: "zookeeper:32181"
        networks:
          - bridge
```

```docker
  kafka-consumer-flink:
        image: kafka-spark-flink-example
        depends_on:
          - kafka-producer
        environment:
          EXAMPLE_GOAL: "consumer.flink"
          EXAMPLE_KAFKA_TOPIC: "example"
          EXAMPLE_KAFKA_SERVER: "kafka:9092"
          EXAMPLE_ZOOKEEPER_SERVER: "zookeeper:32181"
        networks:
          - bridge
```

# Run
Now that everything is in place, it is time to start the containers using the `docker-compose` tool, passing the `-d` argument to detach and run the containers in the background:

```shell
docker-compose up -d
```

Such execution will provide detailed feedback regarding the success of creating and running each container and network:

```shell
Creating network "kafka-spark-flink-example_bridge" with driver "bridge"
Creating kafka-spark-flink-example_kafka-manager_1 ... done
Creating kafka-spark-flink-example_zookeeper_1     ... done
Creating kafka-spark-flink-example_kafka_1         ... done
Creating kafka-spark-flink-example_kafka-producer_1 ... done
Creating kafka-spark-flink-example_kafka-consumer-flink_1 ... done
Creating kafka-spark-flink-example_kafka-consumer-kafka_1 ... done
Creating kafka-spark-flink-example_kafka-consumer-spark_1 ... done
```

To stop and remove all containers, please take advantage of the `down` option of the `docker-compose` tool:

```shell
docker-compose down
```

Detailed feedback about stopping and destroying each container and network is also provided:

```shell
Stopping kafka-spark-flink-example_kafka-consumer-flink_1 ... done
Stopping kafka-spark-flink-example_kafka-consumer-kafka_1 ... done
Stopping kafka-spark-flink-example_kafka-consumer-spark_1 ... done
Stopping kafka-spark-flink-example_kafka_1                ... done
Stopping kafka-spark-flink-example_zookeeper_1            ... done
Stopping kafka-spark-flink-example_kafka-manager_1        ... done
Removing kafka-spark-flink-example_kafka-consumer-flink_1 ... done
Removing kafka-spark-flink-example_kafka-consumer-kafka_1 ... done
Removing kafka-spark-flink-example_kafka-consumer-spark_1 ... done
Removing kafka-spark-flink-example_kafka-producer_1       ... done
Removing kafka-spark-flink-example_kafka_1                ... done
Removing kafka-spark-flink-example_zookeeper_1            ... done
Removing kafka-spark-flink-example_kafka-manager_1        ... done
Removing network kafka-spark-flink-example_bridge
```


# Validate
In order to check if everything is working properly, we can take advantage of the `docker logs` tool to analyse the output being generated on each container. In that context, we can check the logs of the producer and consumers to validate that data is being processed properly.

## Producer
Run the following command to access producer logs:

```shell
docker logs kafka-spark-flink-example_kafka-producer_1 -f
```
    
Output should be similar to the following example, were each line represents a word already sent to Kafka:

```shell
20:43:41.355 [main] INFO  org.davidcampos.kafka.producer.KafkaProducerExample - Sent (ac8f0337-bbde-4e92-8659-c847aa7b7eaf, four) to topic example @ 1525725821264.
20:43:41.468 [main] INFO  org.davidcampos.kafka.producer.KafkaProducerExample - Sent (6ece8f3c-72b8-40a0-a37f-398d6cb9ee76, six) to topic example @ 1525725821455.
20:43:41.590 [main] INFO  org.davidcampos.kafka.producer.KafkaProducerExample - Sent (9eba2ad9-5926-4eac-b3b4-1bde27209d77, two) to topic example @ 1525725821569.
20:43:41.768 [main] INFO  org.davidcampos.kafka.producer.KafkaProducerExample - Sent (0eb0c80b-760e-47f3-8a73-f86868d83ff4, two) to topic example @ 1525725821694.
20:43:41.876 [main] INFO  org.davidcampos.kafka.producer.KafkaProducerExample - Sent (ca247271-07b4-4bb9-834a-27ec5168e9cf, two) to topic example @ 1525725821869.
20:43:41.985 [main] INFO  org.davidcampos.kafka.producer.KafkaProducerExample - Sent (ab715932-0b28-46cb-9c89-b6965e34619c, eight) to topic example @ 1525725821977.
20:43:42.103 [main] INFO  org.davidcampos.kafka.producer.KafkaProducerExample - Sent (74b60cc9-0849-4468-8125-fd6b368e5e66, three) to topic example @ 1525725822087.
20:43:42.218 [main] INFO  org.davidcampos.kafka.producer.KafkaProducerExample - Sent (51d80cf5-d601-476b-9eb6-33f44ca94716, ten) to topic example @ 1525725822204.
20:43:42.329 [main] INFO  org.davidcampos.kafka.producer.KafkaProducerExample - Sent (0a9a20b1-06c9-4103-ac3d-66bc48397936, eight) to topic example @ 1525725822318.
```

## Kafka consumer
To review Kafka consumer logs:

```shell
docker logs kafka-spark-flink-example_kafka-consumer-kafka_1 -f
```

In this first consumer, for each record consumed, we only print the respective word, in order to validate that messages are being properly sent and received:

```shell
21:36:04.742 [main] INFO  org.davidcampos.kafka.consumer.KafkaConsumerExample - Consumer Record:(c73ec71c-866a-411a-93ab-e7ff2b5bcc46, ten, 0, 0)
21:36:04.800 [main] INFO  org.davidcampos.kafka.consumer.KafkaConsumerExample - Consumer Record:(62ea7d3f-70f2-4d4e-9c04-ca9d8c2165f5, one, 0, 1)
21:36:04.911 [main] INFO  org.davidcampos.kafka.consumer.KafkaConsumerExample - Consumer Record:(0de6850c-4817-4994-be7f-fcc5b3480d5c, five, 0, 2)
21:36:05.023 [main] INFO  org.davidcampos.kafka.consumer.KafkaConsumerExample - Consumer Record:(6d13af57-e186-465d-ac87-fb93d2c5bc16, ten, 0, 3)
21:36:05.135 [main] INFO  org.davidcampos.kafka.consumer.KafkaConsumerExample - Consumer Record:(ee7cef69-4e60-4a20-b2e1-85e17720bb68, six, 0, 4)
21:36:05.270 [main] INFO  org.davidcampos.kafka.consumer.KafkaConsumerExample - Consumer Record:(f26b4280-a2a2-4def-9c90-5ea59520f9d1, three, 0, 5)
21:36:05.391 [main] INFO  org.davidcampos.kafka.consumer.KafkaConsumerExample - Consumer Record:(fb3ad922-eb3d-42ed-907e-2831d083ff9e, nine, 0, 6)
```

## Spark consumer
To check Spark consumer logs please run:

```shell
docker logs kafka-spark-flink-example_kafka-consumer-spark_1 -f
```

Every 5s, Spark will output the number of occurrences for each word for that specific period of time, similar to:

```shell
(two,3)
(one,3)
(nine,5)
(six,8)
(three,2)
(five,2)
(four,9)
(seven,3)
(eight,6)
(ten,6)
```

Additionally, you can also check the **Spark UI interface** available at [http://localhost:4040](http://localhost:4040){:target="_blank"}. Such web-based tool provides relevant information for monitoring and instrumentation, with detailed information about the jobs executed, elapsed time, memory usage, among others.


![Spark Interface](/assets/kafka-spark-flink-example/spark.png){: .image-center .img-thumbnail}
***Figure:** Spark interface to check active jobs and respective status.*

## Flink consumer
Finally, one can check Flink logs by executing:

```shell
docker logs kafka-spark-flink-example_kafka-consumer-flink_1 -f
```

Since Flink is a timeseries-based approach it reacts to every message received. As a result, for every word received the respective total number of occurrences is displayed, as we can see below:

```shell
1> (ten,85)
4> (nine,104)
1> (ten,86)
4> (five,91)
4> (one,94)
4> (six,90)
1> (three,89)
4> (six,91)
4> (five,92)
```

# We did it!
The producer is sending the messages to Kafka and all consumers are receiving and processing the messages, showing the number of occurrences for each word.

![GIF](/assets/kafka-spark-flink-example/yes.gif){: .image-center}

# Scale it up
Just one more thing. What about increasing the number of messages being sent? As a first approach, we can change the time interval between requests. By default, this value is set to 100ms, which means that a message is sent every 100ms. To change this behaviour, set the `EXAMPLE_PRODUCER_INTERVAL` environment variable to specify the producer time interval between requests to Kafka. Thus, changing the `docker-compose.yml` accordingly (line 10), we can send a word to Kafka every 10ms.

```docker
kafka-producer:
    image: kafka-spark-flink-example
    depends_on:
      - kafka
    environment:
      EXAMPLE_GOAL: "producer"
      EXAMPLE_KAFKA_TOPIC: "example"
      EXAMPLE_KAFKA_SERVER: "kafka:9092"
      EXAMPLE_ZOOKEEPER_SERVER: "zookeeper:32181"
      EXAMPLE_PRODUCER_INTERVAL: 10
    networks:
      - bridge
```

In order to scale the number of messages even further, two different options can be considered:
- Add multi-thread support to producer in order to send multiple messages at the same time;
- Have multiple producer containers sending multiple messages at the same time.

Considering the example context, it is more straightforward to take advantage of Docker to run multiple containers of the producer service. In a real world-application, a less resource intensive approach might be considered.
Thus, in order to change the number of replicas for the producer service, we can take advantage of the `--scale` argument of `docker-compose up`. It works by specifying the number of containers for the service name, such as `--scale <service_name>=<number_of_containers>`. 
In the next example we request three containers for the `kafka-producer` service:

```shell
docker-compose up -d --scale kafka-producer=3
```

When you do this, in the output you can check Docker starting three different containers for the producer service:

```shell
Creating kafka-spark-flink-example_kafka-producer_1 ... done
Creating kafka-spark-flink-example_kafka-producer_2 ... done
Creating kafka-spark-flink-example_kafka-producer_3 ... done
```

After a while, instead of receiving ~50 messages every 5s, we receive almost 1000 messages per 5s, which represents a 20x increase with just some small changes. The Spark consumer logs confirm the high number of words received in 5s:

```shell
-------------------------------------------
Time: 1525543330000 ms
-------------------------------------------
(two,92)
(one,96)
(nine,83)
(six,113)
(three,88)
(five,82)
(four,100)
(seven,91)
(eight,106)
(ten,88)
```

Besides this simple exercise to scale up the example, keep in mind that with only three servers, Jay Kreps was able to write 2 million messages per second into Kafka and read almost 1 million records from Kafka in a single thread. Such example reflects the scalability and processing power of Kafka. For a more detailed analysis, you can access this Kafka benchmark in the [LinkedIn Engineering Blog](https://engineering.linkedin.com/kafka/benchmarking-apache-kafka-2-million-writes-second-three-cheap-machines){:target="_blank"}.


# Conclusion
I hope this example helps to understand how Kafka can be used as a communication broker between producers and consumers with different purposes.
Nonetheless, keep in mind that using Kafka in large-scale applications with hundreds of thousands of producers and consumers requires high level of expertise for configuring and maintaining the service running with expected availability, performance, robustness and fault tolerance behaviour. Several companies already provide enterprise Kafka services for large-scale applications, such as
[Clonfluent](https://www.confluent.io/){:target="_blank"},
[Amazon](https://aws.amazon.com/pt/kafka/){:target="_blank"},
[Azure](https://azure.microsoft.com/en-us/services/hdinsight/apache-kafka/){:target="_blank"} and
[Cloudera](https://www.cloudera.com/products/open-source/apache-hadoop/apache-kafka.html){:target="_blank"}.
Not saying it is cheap, but it is definitely an option if such expertise is not in the company portfolio.

Please remember that your comments, suggestions and contributions are more than welcome. 

**Happy Kafking and Streaming! :smile:**