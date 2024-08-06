#!/bin/bash

# copy the agent and the spark plugin to make sure they're loaded before the spark starts
wget 'https://repo1.maven.org/maven2/io/pyroscope/agent/0.14.0/agent-0.14.0.jar' -P '/databricks/jars/'
wget 'https://repo1.maven.org/maven2/ch/cern/sparkmeasure/spark-plugins_2.12/0.3/spark-plugins_2.12-0.3.jar' -P '/databricks/jars/'
