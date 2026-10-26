# terraform-aws-eks-gpu

Terraform for an EKS cluster with a GPU node group that sits at zero nodes until you need it. I built it to practice the part of GPU platforms that costs the most money: keeping expensive nodes off unless a job is running.

**Read this first:** I have validated this code but I have not applied it to an AWS account. CI runs `terraform validate`, tflint and a Trivy scan on every push. Nothing in this repo has created real infrastructure, so expect to adjust things on a first real run.

## What it builds

- A VPC with two private and two public subnets, and one NAT gateway (cheap for a lab; a real cluster would use one per zone).
- An EKS cluster whose public API is limited to the IP addresses you list.
- A small always-on `system` node group so CoreDNS and controllers have somewhere to run.
- A `gpu` node group using the NVIDIA EKS AMI. It starts at 0 nodes, defaults to Spot, and is tainted so ordinary pods can't land on it.

It uses the community `terraform-aws-modules` VPC and EKS modules instead of hand-writing every resource.

## Use it

```
cp terraform.tfvars.example terraform.tfvars   # put your own IP in api_allowed_cidrs
terraform init
terraform plan
terraform apply
```

`api_allowed_cidrs` has no default and rejects `0.0.0.0/0`, so the API can't be left open to the world by accident.

Then:

```
$(terraform output -raw kubeconfig_command)
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.0/deployments/static/nvidia-device-plugin.yml
```

The NVIDIA device plugin is what makes `nvidia.com/gpu` show up as a resource, so the cluster needs it. I left it out of Terraform on purpose to keep this to infrastructure only.

## Turning a GPU on and off

Nothing runs on the GPU group by default. To start a node, raise the desired size (the `scale_gpu_up_command` output has an example) or set `gpu_desired_size` and apply. To test it:

```
kubectl apply -f k8s/gpu-test.yaml
kubectl logs gpu-test
```

You should see the `nvidia-smi` table. Scale the group back to 0 when you're done.

The node group is tagged so a cluster autoscaler could manage it, but I haven't included one. Karpenter would be the next step.

## Kubernetes version

The default is 1.35. EKS charges extra for versions that have left standard support, and old versions are retired on a schedule, so check the [EKS version calendar](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html) and update `kubernetes_version` before you apply.

## Cost

The pieces that bill while idle: the EKS control plane, the NAT gateway and the two system nodes. The GPU group costs nothing at 0. Run `terraform destroy` when you finish experimenting.

## CI

Each push runs `terraform fmt -check`, `terraform init` and `validate`, tflint, a Trivy config scan, and a kubeconform check on the test pod.

## Scan exceptions

Three Trivy findings are ignored in `.trivyignore`, each with the reason next to it: the public API endpoint (limited to your IP), open outbound traffic from worker nodes (needed to pull images), and the VPC module's default network ACLs (security groups do the filtering).

## License

MIT
