---
title: Ceph Bucket Notification(Ceph 存储桶通知)
tags:
  - ceph
categories:
  - ceph
abbrlink: 24828
date: 2021-09-13 08:22:19
---

# 介绍

存储桶通知提供了一种在存储同上发生某些事件时将消息发送到 radosgw 之外的机制。当前，通知可以发送到：HTTP、AMQP 0.9.1 和 Kafka

# 实验

## 搭建一个 ceph 对象存储集群

参考 ceph 官方文档搭建：https://docs.ceph.com/en/latest/

## 搭建一个简易的 server，提供 API 接收通知

> 文件 `server.py`

```python
#!/usr/bin/env python3

import logging
from http.server import BaseHTTPRequestHandler, HTTPServer
from sys import argv


class S(BaseHTTPRequestHandler):
    def _set_response(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

    def do_GET(self):
        logging.info(f"GET request\nPath: {self.path}\nHeaders:\n{self.headers}\n")
        self._set_response()
        self.wfile.write(f"GET request for {self.path}".encode('utf-8'))

    def do_POST(self):
        content_length = int(self.headers["Content-Length"])
        post_data = self.rfile.read(content_length)
        logging.info(
            f"POST request\nPath: {self.path}\nHeaders:\n{self.headers}\nBody:\n{post_data.decode('utf-8')}\n",
        )

        self._set_response()
        self.wfile.write(f"POST request for {self.path}".encode('utf-8'))


def run(server_class=HTTPServer, handler_class=S, port=8080):
    logging.basicConfig(level=logging.INFO)
    server_address = ("", port)
    httpd = server_class(server_address, handler_class)
    logging.info("Starting httpd...\n")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logging.info("Stopping httpd...\n")


if __name__ == "__main__":
    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()
```

> 执行 `python3 server.py 8080`

## 创建 topic、bucket 以及 bucket 更新通知机制

> 文件 `notify.py`

```python
import argparse
import json

import boto3
import botocore

"""This class configures bucket notifications for both kafka and rabbitmq endpoints for real-time message queuing"""


class Notifier:
    def __init__(self):

        # creates all needed arguments for the program to run
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "-e",
            "--endpoint-url",
            help="endpoint url for s3 object storage",
            required=True,
        )
        parser.add_argument(
            "-a",
            "--access-key",
            help="access key for s3 object storage",
            required=True,
        )
        parser.add_argument(
            "-s",
            "--secret-key",
            help="secret key for s3 object storage",
            required=True,
        )
        parser.add_argument("-b", "--bucket-name", help="s3 bucket name", required=True)
        parser.add_argument(
            "-ke",
            "--kafka-endpoint",
            help="kafka endpoint in which rgw will send notifications to",
            required=False,
        )
        parser.add_argument(
            "-ae",
            "--amqp-endpoint",
            help="amqp endpoint in which rgw will send notifications to",
            required=False,
        )
        parser.add_argument(
            "-he",
            "--http-endpoint",
            help="http endpoint in which rgw will send notifications to",
            required=False,
        )
        parser.add_argument(
            "-t",
            "--topic",
            help="topic name in which rgw will send notifications to",
            required=True,
        )
        parser.add_argument(
            "-f",
            "--filter",
            help="filter such as prefix, suffix, metadata or tags",
            required=False,
        )
        parser.add_argument(
            "-o",
            "--opaque",
            help="opaque data that will be sent in the notifications",
            required=False,
        )
        parser.add_argument(
            "-x",
            "--exchange",
            help="amqp exchange name (mandatory for amqp endpoints)",
            required=False,
        )
        parser.add_argument(
            "-n",
            "--notification",
            help="notification name, allows for setting multiple notifications on the same bucket",
            required=False,
            default="configuration",
        )

        # parsing all arguments
        args = parser.parse_args()

        # building instance vars
        self.endpoint_url = args.endpoint_url
        self.access_key = args.access_key
        self.secret_key = args.secret_key
        self.bucket_name = args.bucket_name
        self.kafka_endpoint = args.kafka_endpoint
        self.http_endpoint = args.http_endpoint
        self.amqp_endpoint = args.amqp_endpoint
        self.topic = args.topic
        self.filter = args.filter
        self.opaque = args.opaque
        self.exchange = args.exchange
        self.notification = args.notification
        self.sns = boto3.client(
            "sns",
            endpoint_url=self.endpoint_url,
            aws_access_key_id=self.access_key,
            region_name="default",
            aws_secret_access_key=self.secret_key,
            config=botocore.client.Config(signature_version="s3"),
        )

        self.s3 = boto3.client(
            "s3",
            endpoint_url=self.endpoint_url,
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            region_name="default",
            config=botocore.client.Config(signature_version="s3"),
        )

    """ This function creates and sns-like topic with configured push endpoint"""

    def create_sns_topic(self):

        attributes = {}

        if self.opaque:
            attributes["OpaqueData"] = self.opaque

        # in case wanted MQ endpoint is kafka
        if self.kafka_endpoint:
            attributes["push-endpoint"] = "kafka://" + self.kafka_endpoint
            attributes["kafka-ack-level"] = "broker"

        # in case wanted MQ endpoint is rabbitmq
        elif self.amqp_endpoint:
            attributes["push-endpoint"] = "amqp://" + self.amqp_endpoint
            attributes["amqp-exchange"] = self.exchange_name
            attributes["amqp-ack-level"] = "broker"

        # in case wanted MQ endpoint is http
        elif self.http_endpoint:
            attributes["push-endpoint"] = "http://" + self.http_endpoint

        # in case wanted MQ endpoint is not provided by the user
        else:
            raise Exception("please configure a push endpoint!")

        # creates the wanted sns-like topic on RGW and gets the topic's ARN
        self.topic_arn = self.sns.create_topic(Name=self.topic, Attributes=attributes)["TopicArn"]

    """ This function configures bucket notification for object creation and removal """

    def configure_bucket_notification(self):

        # creates a bucket if it doesn't exists
        try:
            self.s3.head_bucket(Bucket=self.bucket_name)
        except botocore.exceptions.ClientError:
            self.s3.create_bucket(Bucket=self.bucket_name)

        # initial dictionary
        bucket_notifications_configuration = {
            "TopicConfigurations": [
                {
                    "Id": self.notification,
                    "TopicArn": self.topic_arn,
                    "Events": ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"],
                },
            ],
        }

        # in case the user has provided a filter to use
        if self.filter:
            bucket_notifications_configuration["TopicConfigurations"][0].update(
                {"Filter": json.loads(self.filter)},
            )

        # pushed the notification configuration to the bucket
        self.s3.put_bucket_notification_configuration(
            Bucket=self.bucket_name,
            NotificationConfiguration=bucket_notifications_configuration,
        )


if __name__ == "__main__":
    # creates an notifier instance from class
    notifier = Notifier()

    # create sns-like topic sent to MQ endpoint
    notifier.create_sns_topic()

    # configures object creation and removal based notification for the bucket
    notifier.configure_bucket_notification()
```

> 执行 `python3 notify.py -h` 查看帮助

## 验证

- 往 `notify.py` 脚本中新建的 bucket 中上传文件，可以看到如下信息：

```json
{
    "Records":[
        {
            "eventVersion":"2.2",
            "eventSource":"ceph:s3",
            "awsRegion":"",
            "eventTime":"2021-04-29 03:44:09.933439Z",
            "eventName":"s3:ObjectCreated:Put",
            "userIdentity":{
                "principalId":"7b10eee340c84201bc99ca5d8fa4f61d"
            },
            "requestParameters":{
                "sourceIPAddress":""
            },
            "responseElements":{
                "x-amz-request-id":"cffa8590-7621-4f07-99b4-5f5f5a30baab.4451.127",
                "x-amz-id-2":"1163-default-default"
            },
            "s3":{
                "s3SchemaVersion":"1.0",
                "configurationId":"configuration",
                "bucket":{
                    "name":"test-notifications",
                    "ownerIdentity":{
                        "principalId":"7b10eee340c84201bc99ca5d8fa4f61d"
                    },
                    "arn":"arn:aws:s3:::test-notifications",
                    "id":"cffa8590-7621-4f07-99b4-5f5f5a30baab.4478.23"
                },
                "object":{
                    "key":"charging-simple-logic.png",
                    "size":9613,
                    "etag":"e517ba5e9e85f66a5bba81109ab4652e",
                    "versionId":"",
                    "sequencer":"892B8A60D2CAEF37",
                    "metadata":[
                        {
                            "key":"x-amz-content-sha256",
                            "val":"91af6adc28cbee8a82d186604f03a062b4ee64e26caebbd5d5da8e41182a1cdf"
                        },
                        {
                            "key":"x-amz-date",
                            "val":"20210429T034409Z"
                        }
                    ],
                    "tags":[

                    ]
                }
            },
            "eventId":"1619667849.938461.e517ba5e9e85f66a5bba81109ab4652e",
            "opaqueData":""
        }
    ]
}
```
