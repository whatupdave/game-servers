variable "region" {
  default = "us-west-1"
}

variable "instance_type" {
  default = "m3.medium"
}

variable "key_name" {
  description = "The aws ssh key name."
  default = "ecs"
}

variable "cluster_name" {
  default = "ecs"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_launch_configuration" "ecs" {
  image_id = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"
  spot_price = "0.05"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.ecs.id}"]

  user_data = "${ template_file.user_data.rendered }"

  lifecycle { create_before_destroy = true }
}

resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name = "ecs_instance_role_policy"
  policy = "${file("../policies/ecs-instance-role-policy.json")}"
  role = "${aws_iam_role.ecs_role.id}"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "ecs-instance-profile"
  path = "/"
  roles = ["${aws_iam_role.ecs_role.name}"]
}

resource "aws_iam_role" "ecs_role" {
  name = "ecs_role"
  assume_role_policy = "${file("../policies/ecs-role.json")}"
}

resource "aws_autoscaling_group" "ecs" {
  name = "games-asg"
  launch_configuration = "${aws_launch_configuration.ecs.name}"
  availability_zones = ["${var.region}a"]
  min_size = 1
  max_size = 1
  desired_capacity = 1

  tag {
    key = "Name"
    value = "gs"
    propagate_at_launch = true
  }
}

resource "aws_ecs_cluster" "ecs" {
	name = "ecs"
}
