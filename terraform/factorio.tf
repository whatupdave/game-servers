variable "domain" {
  description = "domain registered in dnsimple"
}

variable "subdomain" {
  description = "XXXX.mydomain.com"
}

variable "dnsimple_token" {
  description = "<email>:<token>"
}

resource "aws_ebs_volume" "factorio" {
  availability_zone = "${var.region}a"
  size = 40
  tags {
    Name = "factorio"
  }
}

resource "aws_ecs_task_definition" "factorio" {
  family = "factorio"
  container_definitions = "${file("../task-definitions/factorio.json")}"

  volume {
    name = "factorio-data"
    host_path = "/data/factorio-data"
  }

  volume {
    name = "factorio-mods"
    host_path = "/data/factorio-mods"
  }
}

resource "aws_ecs_service" "factorio" {
  name = "factorio"
  cluster = "${aws_ecs_cluster.ecs.id}"
  task_definition = "${aws_ecs_task_definition.factorio.arn}"
  desired_count = 1
}
