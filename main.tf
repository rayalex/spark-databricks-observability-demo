data "databricks_current_user" "me" {

}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

data "databricks_node_type" "smallest" {
  local_disk = true
}

resource "databricks_workspace_file" "pyroscope_init" {
  source = "${path.module}/init-pyroscope.sh"
  path   = "${data.databricks_current_user.me.home}/dbx-obs-demo/init-pyroscope.sh"
}

resource "databricks_dbfs_file" "prometheus_jar" {
  source = "${path.module}/lib/spark-metrics-assembly-3.5-1.0.0.jar"
  path   = "/jars/dbx-obs-demo/spark_metrics.jar"
}

resource "databricks_workspace_file" "prometheus_init" {
  source = "${path.module}/init-prometheus.sh"
  path   = "${data.databricks_current_user.me.home}/dbx-obs-demo/init-prometheus.sh"
}

// For demo purposes, we will use a single-user assigned cluster, no autoscaling
resource "databricks_cluster" "demo" {
  cluster_name            = "DBX Observability Demo"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 30
  num_workers             = 0

  init_scripts {
    workspace {
      destination = databricks_workspace_file.pyroscope_init.path
    }
  }

  init_scripts {
    workspace {
      destination = databricks_workspace_file.prometheus_init.path
    }
  }

  spark_conf = {
    // single-node cluster
    "spark.master" : "local[*]",
    "spark.databricks.cluster.profile" : "singleNode"

    // pyroscope configuration
    "spark.pyroscope.server" : "http://${var.pyroscope_host}",
    "spark.pyroscope.applicationName" : "dbx-obs-demo",
    "spark.plugins" : "ch.cern.PyroscopePlugin"
  }

  spark_env_vars = {
    "PROMETHEUS_HOST" : var.prometheus_pushgateway_host
    "PROMETHEUS_JOB_NAME" : "dbx-interractive"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  cluster_log_conf {
    dbfs {
      destination = "dbfs:/cluster-logs"
    }
  }
}

