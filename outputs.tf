output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "kubeconfig_command" {
  description = "Run this to point kubectl at the cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "scale_gpu_up_command" {
  description = "Example of turning a GPU node on"
  value       = "aws eks update-nodegroup-config --region ${var.region} --cluster-name ${module.eks.cluster_name} --nodegroup-name <gpu node group name> --scaling-config minSize=0,maxSize=${var.gpu_max_size},desiredSize=1"
}
