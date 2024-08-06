#!/bin/bash

# copy over necessary jars
cp ${metrics_jar_path} /databricks/jars

# configure jmx
cat > /databricks/spark/conf/jmxCollector.yaml <<EOL
lowercaseOutputName: false
lowercaseOutputLabelNames: false
whitelistObjectNames: ["*:*"]
EOL

# configure spark metrics to use pushgateway as target
pushgatewayHost=$PROMETHEUS_HOST
pushgatewayJobName=$PROMETHEUS_JOB_NAME
cat >> /databricks/spark/conf/metrics.properties <<EOL
# Enable Prometheus for all instances by class name
*.sink.prometheus.class=org.apache.spark.banzaicloud.metrics.sink.PrometheusSink
# Prometheus pushgateway address
*.sink.prometheus.pushgateway-address-protocol=http
*.sink.prometheus.pushgateway-address=$pushgatewayHost
*.sink.prometheus.period=5
# *.sink.prometheus.pushgateway-enable-timestamp=true
# Metrics name processing (version 2.3-1.1.0 +)
# *.sink.prometheus.metrics-name-capture-regex=<regular expression to capture sections metric name sections to be replaces>
# *.sink.prometheus.metrics-name-replacement=<replacement captured sections to be replaced with>
*.sink.prometheus.labels=job_name=$pushgatewayJobName
# Support for JMX Collector (version 2.3-2.0.0 +)
*.sink.prometheus.enable-dropwizard-collector=true
*.sink.prometheus.enable-jmx-collector=true
*.sink.prometheus.jmx-collector-config=/databricks/spark/conf/jmxCollector.yaml

# Enable HostName in Instance instead of Appid (Default value is false)
*.sink.prometheus.enable-hostname-in-instance=true

# Enable JVM metrics source for all instances by class name
*.sink.jmx.class=org.apache.spark.metrics.sink.JmxSink
*.source.jvm.class=org.apache.spark.metrics.source.JvmSource

# Use custom metric filter
# *.sink.prometheus.metrics-filter-class=com.example.RegexMetricFilter
# *.sink.prometheus.metrics-filter-regex=com.example\.(.*)
EOL
