variable "region" {
  description = "AWS region to build in"
  type        = string
  default     = "us-east-2"
}

variable "name" {
  description = "Name used for the cluster and everything around it"
  type        = string
  default     = "gpu-lab"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.35"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "api_allowed_cidrs" {
  description = "Who may reach the public Kubernetes API. Set this to your own IP, for example [\"203.0.113.7/32\"]."
  type        = list(string)

  validation {
    condition     = length(var.api_allowed_cidrs) > 0 && !contains(var.api_allowed_cidrs, "0.0.0.0/0")
    error_message = "Give at least one CIDR and do not use 0.0.0.0/0."
  }
}

variable "system_instance_types" {
  description = "Instance types for the small always-on node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "gpu_instance_types" {
  description = "Instance types for the GPU node group"
  type        = list(string)
  default     = ["g5.xlarge"]
}

variable "gpu_capacity_type" {
  description = "ON_DEMAND or SPOT. Spot is cheaper and fine for training jobs that can restart."
  type        = string
  default     = "SPOT"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.gpu_capacity_type)
    error_message = "Use ON_DEMAND or SPOT."
  }
}

variable "gpu_max_size" {
  description = "Most GPU nodes the group may ever run"
  type        = number
  default     = 2
}

variable "gpu_desired_size" {
  description = "How many GPU nodes to start with. 0 means no GPU cost until you scale up."
  type        = number
  default     = 0
}
