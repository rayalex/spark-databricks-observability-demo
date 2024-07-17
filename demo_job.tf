resource "databricks_notebook" "calculate_pi" {
  path     = "${data.databricks_current_user.me.home}/dbx-obs-demo/CalculatePi"
  language = "SCALA"
  content_base64 = base64encode(<<-EOT
    import scala.math.random

    val n = 1000000000

    val count = sc.parallelize(1 to n).map { i =>
    val x = random * 2 - 1
    val y = random * 2 - 1

    if (x*x + y*y < 1) 1 else 0
    }.reduce(_ + _)

    println("Pi is roughly " + 4.0 * count / n)
    EOT
  )
}

resource "databricks_job" "demo-job" {
  name = "DBX Observability Demo Job"

  task {
    task_key = "calculate-pi"

    new_cluster {
      num_workers   = 4
      spark_version = data.databricks_spark_version.latest_lts.id
      node_type_id  = data.databricks_node_type.smallest.id

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
        // pyroscope configuration
        "spark.pyroscope.server" : "http://${var.pyroscope_host}",
        "spark.pyroscope.applicationName" : "dbx-obs-demo",
        "spark.plugins" : "ch.cern.PyroscopePlugin"
      }

      spark_env_vars = {
        "PROMETHEUS_HOST" : var.prometheus_pushgateway_host
        "PROMETHEUS_JOB_NAME" : "dbx-calculate-pi"
      }
    }

    notebook_task {
      notebook_path = databricks_notebook.calculate_pi.path
    }
  }
}