#!/bin/bash

# Just run two consumer instances in parallel
java -jar consumer.jar worker1 &
java -jar consumer.jar worker2 &
wait
