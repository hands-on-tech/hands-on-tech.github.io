---
layout: post
title:  "Cassandra with JPA: Datastax vs. Kundera vs. Achilles"
subtitle:  "Project using JPA to communicate with Cassandra and comparing existing libraries performance and resources usage."
date:   2018-11-02 10:00:00 +0100
author: david_campos
tags: cassandra jpa datastax kundera achilles java docker
comments: true
read_time: true
background: '/assets/cassandra-jpa-example/background.jpg'
---

# TL;DR
Project using JPA to communicate with Cassandra comparing Datastax, Kundera and Achilles libraries.
Kundera presents better processing speeds also with lower computational resources usage.

**Source code is available on [Github](https://github.com/hands-on-tech/cassandra-jpa-example){:target="_blank"}** with detailed documentation on how to build and run the tests using Docker.

# Goal
With the overwhelming amounts of data being generated in nowadays technological solutions, one of the main challenges is to find the best solutions to properly store, manage and serve huge amounts of data. Apache Cassandra is one of such solutions, which is a NoSQL database designed for large-scale data management with high availability, consistency and performance. When performing millions of operations per day on top of such databases, every millisecond counts with significant impact on overall system behaviour.

**The main goal of this project is to use different Java libraries to communicate with Cassandra, comparing usage complexity, processing speeds and resources usage**. The following architecture is proposed to achieve the aforementioned goal, which contains the following components and interfaces:
- **Cassandra**: database for large-scale data management;
- **Datastax Native**: Java library to communicate with Cassandra;
- **Datastax ORM**: Java library to communicate with Cassandra;
- **Kundera**: Java library to communicate with Cassandra;
- **Achilles**: Java library to communicate with Cassandra.

![Architecture](/assets/cassandra-jpa-example/architecture.svg){: .image-center}
***Figure:** Illustration of the implementation architecture of the Cassandra and JPA.*

The aforementioned architecture is provided using following technologies:
- **Jave 8**: main programming language for experiment;
- **Maven**: dependency management and package building;
- **Docker**: components containerization, orchestration and setup;
- **Docker Compose**: simplify running multi-container solutions with dependencies.

# Apache Cassandra
- Key concepts
- Performance comparison with other NoSQL databases


![NoSQL Popularity](/assets/cassandra-jpa-example/nosql_popularity.png){: .image-center .image-rounded-corners}
***Figure:** Popularity of several NoSQL databases from [DB-Engines](https://db-engines.com){:target="_blank"}.*

Not straighforward to find isent and transparent comparisons of NoSQL solutions.

Performance comparisons:
-  Çankaya University: https://www.researchgate.net/profile/Murat_Saran/publication/321622083_A_Comparison_of_NoSQL_Database_Systems_A_Study_on_MongoDB_Apache_Hbase_and_Apache_Cassandra/links/5a29173a4585155dd42796db/A-Comparison-of-NoSQL-Database-Systems-A-Study-on-MongoDB-Apache-Hbase-and-Apache-Cassandra.pdf


- Cassandra Frieds: (End Point company)http://www.datastax.com/wp-content/themes/datastax-2014-08/files/NoSQL_Benchmarks_EndPoint.pdf
- Couchbase friends: https://info.couchbase.com/rs/302-GJY-034/images/2018Altoros_NoSQL_Performance_Benchmark.pdf

![NoSQL Performance](/assets/cassandra-jpa-example/nosql_performance.png){: .image-center .image-rounded-corners}
***Figure:** Performance of several NoSQL databases from [EndPoint](http://www.datastax.com/wp-content/themes/datastax-2014-08/files/NoSQL_Benchmarks_EndPoint.pdf){:target="_blank"}.*

Overall, Cassandra better at large-scale and more write than read use cases.






# JPA libraries
List of existing clients for Java:
- Achilles
- Astyanax (deprecated and is no longer supported)
- Casser (small community)
- Datastax Java driver
- Kundera
- PlayORM (for Play Framework)


Introduction to:
- Datastax
- Kundera
- Achilles

# Comparison
- iterations
- repetitions
- simple user data
- write, read, update, delete operations
- register CPU and RAM usage

# Cassandra Server

```yml
version: '3.6'

networks:
  bridge:
    driver: bridge

services:
  cassandra:
    image: cassandra:3.11
    environment:
      CASSANDRA_START_RPC: "true"
      CASSANDRA_CLUSTER_NAME: cassandra
    networks:
      bridge:
        aliases:
        - cassandra
```
***Code:** `docker-compose.yml` file for running Cassandra.*

- No good web UI solution is available to access cassandra databases

# Configurations

- iterations
- repetitions
- UUIDs

```java
public final static int ITERATIONS = System.getenv("EXAMPLE_ITERATIONS") != null ?
		Integer.parseInt(System.getenv("EXAMPLE_ITERATIONS")) : 1000;

public final static int REPETITIONS = System.getenv("EXAMPLE_REPETITIONS") != null ?
		Integer.parseInt(System.getenv("EXAMPLE_REPETITIONS")) : 5;

public static List<UUID> uuids = generateUUIDs();

public final static String EXAMPLE_CASSANDRA_HOST = System.getenv("EXAMPLE_CASSANDRA_HOST") != null ?
		System.getenv("EXAMPLE_CASSANDRA_HOST") : "cassandra";

public final static String EXAMPLE_CASSANDRA_PORT = System.getenv("EXAMPLE_CASSANDRA_PORT") != null ?
		System.getenv("EXAMPLE_CASSANDRA_PORT") : "9160";

public final static long EXAMPLE_REQUEST_WAIT = System.getenv("EXAMPLE_REQUEST_WAIT") != null ?
		Long.parseLong(System.getenv("EXAMPLE_REQUEST_WAIT")) : 3;
```
***Code:** `docker-compose.yml` file for running Cassandra.*


# Datastax Native implementation

# Datastax ORM implementation

# Kundera implementation

- To turn Kundera logging of, logback.xml on resources folder:

```xml 
<configuration>
    <root level="ERROR"></root>
</configuration>
```

- To create database: `<property name="kundera.ddl.auto.prepare" value="create"/>`
- To work with stored values, remove previous line

# Achilles implementation

- Achilles integration with IDE and generating mapping sources sucks
	- Reminds me of SOAP times
	- Everytime that you change the POJO classes mapping with the database, you need to rebuild the project to rebuild the classes




Error: RPC true on cassandra:

```shell
Exception in thread "main" com.impetus.kundera.configure.schema.SchemaGenerationException: org.apache.thrift.transport.TTransportException
	at com.impetus.client.cassandra.schemamanager.CassandraSchemaManager.create(CassandraSchemaManager.java:264)
	at com.impetus.kundera.configure.schema.api.AbstractSchemaManager.handleOperations(AbstractSchemaManager.java:264)
	at com.impetus.kundera.configure.schema.api.AbstractSchemaManager.exportSchema(AbstractSchemaManager.java:115)
	at com.impetus.client.cassandra.schemamanager.CassandraSchemaManager.exportSchema(CassandraSchemaManager.java:166)
	at com.impetus.kundera.configure.SchemaConfiguration.configure(SchemaConfiguration.java:191)
	at com.impetus.kundera.configure.ClientMetadataBuilder.buildClientFactoryMetadata(ClientMetadataBuilder.java:48)
	at com.impetus.kundera.persistence.EntityManagerFactoryImpl.configureClientFactories(EntityManagerFactoryImpl.java:408)
	at com.impetus.kundera.persistence.EntityManagerFactoryImpl.configure(EntityManagerFactoryImpl.java:161)
	at com.impetus.kundera.persistence.EntityManagerFactoryImpl.<init>(EntityManagerFactoryImpl.java:135)
	at com.impetus.kundera.KunderaPersistence.createEntityManagerFactory(KunderaPersistence.java:85)
	at javax.persistence.Persistence.createEntityManagerFactory(Persistence.java:79)
	at org.davidcampos.cassandra.Main.main(Main.java:23)
Caused by: org.apache.thrift.transport.TTransportException
	at org.apache.thrift.transport.TIOStreamTransport.read(TIOStreamTransport.java:132)
	at org.apache.thrift.transport.TTransport.readAll(TTransport.java:86)
	at org.apache.thrift.transport.TFramedTransport.readFrame(TFramedTransport.java:129)
	at org.apache.thrift.transport.TFramedTransport.read(TFramedTransport.java:101)
	at org.apache.thrift.transport.TTransport.readAll(TTransport.java:86)
	at org.apache.thrift.protocol.TBinaryProtocol.readAll(TBinaryProtocol.java:429)
	at org.apache.thrift.protocol.TBinaryProtocol.readI32(TBinaryProtocol.java:318)
	at org.apache.thrift.protocol.TBinaryProtocol.readMessageBegin(TBinaryProtocol.java:219)
	at org.apache.thrift.TServiceClient.receiveBase(TServiceClient.java:69)
	at org.apache.cassandra.thrift.Cassandra$Client.recv_execute_cql3_query(Cassandra.java:1734)
	at org.apache.cassandra.thrift.Cassandra$Client.execute_cql3_query(Cassandra.java:1719)
	at com.impetus.client.cassandra.schemamanager.CassandraSchemaManager.onCql3CreateKeyspace(CassandraSchemaManager.java:410)
	at com.impetus.client.cassandra.schemamanager.CassandraSchemaManager.createKeyspace(CassandraSchemaManager.java:317)
	at com.impetus.client.cassandra.schemamanager.CassandraSchemaManager.onCreateKeyspace(CassandraSchemaManager.java:294)
	at com.impetus.client.cassandra.schemamanager.CassandraSchemaManager.createOrUpdateKeyspace(CassandraSchemaManager.java:278)
	at com.impetus.client.cassandra.schemamanager.CassandraSchemaManager.create(CassandraSchemaManager.java:260)
	... 11 more
```

# Packaging

- problem putting everything in the same jar:

```
Exception in thread "main" com.impetus.kundera.loader.MetamodelLoaderException: Error while retrieving and storing entity metadata
	at com.impetus.kundera.configure.MetamodelConfiguration.loadEntityMetadata(MetamodelConfiguration.java:238)
	at com.impetus.kundera.configure.MetamodelConfiguration.configure(MetamodelConfiguration.java:112)
	at com.impetus.kundera.persistence.EntityManagerFactoryImpl.configure(EntityManagerFactoryImpl.java:158)
	at com.impetus.kundera.persistence.EntityManagerFactoryImpl.<init>(EntityManagerFactoryImpl.java:135)
	at com.impetus.kundera.KunderaPersistence.createEntityManagerFactory(KunderaPersistence.java:85)
	at javax.persistence.Persistence.createEntityManagerFactory(Persistence.java:79)
	at org.davidcampos.cassandra.kundera.KunderaExample.runWrites(KunderaExample.java:37)
	at org.davidcampos.cassandra.kundera.KunderaExample.main(KunderaExample.java:21)
	at org.davidcampos.cassandra.Main.main(Main.java:12)
```

	- fixed with:
	- <exclude-unlisted-classes>true</exclude-unlisted-classes>

# CPU and RAM usage
- to get docker stats:
	- install brew install moreutils
	- sh script

# Run
- docker build -t cassandra-jpa-example .

# Results





# Conclusion


Please remember that your comments, suggestions and contributions are more than welcome. 

**Happy Cassandring! :smile:**