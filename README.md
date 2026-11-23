# terraform-aws-eks-gpu

[![CI](https://github.com/gkakkineni-devops/terraform-aws-eks-gpu/actions/workflows/ci.yml/badge.svg)](https://github.com/gkakkineni-devops/terraform-aws-eks-gpu/actions/workflows/ci.yml)

Terraform for an EKS cluster with a GPU node group that sits at zero nodes until you need it. I built it to practice the part of GPU platforms that costs the most money: keeping expensive nodes off unless a job is running.

**Read this first:** I have validated this code but I have not applied it to an AWS account. CI runs `terraform validate`, tflint and a Trivy scan on every push. Nothing in this repo has created real infrastructure, so expect to adjust things on a first real run.

## What it builds

- A VPC with two private and two public subnets, and one NAT gateway (cheap for a lab; a real cluster would use one per zone).
- An EKS cluster whose public API is limited to the IP addresses you list.
- A small always-on `system` node group so CoreDNS and controllers have somewhere to run.
- A `gpu` node group using the NVIDIA EKS AMI. It starts at 0 nodes, defaults to Spot, and is tainted so ordinary pods can't land on it.

It uses the community `terraform-aws-modules` VPC and EKS modules instead of hand-writing every resource.

```mermaid
flowchart TB
  you[You: terraform apply] --> vpc[VPC: 2 public + 2 private subnets, 1 NAT]
  vpc --> eks[EKS control plane, API limited to your IP]
  eks --> sys[system node group: 2 small nodes, always on]
  eks --> gpu[gpu node group: 0 nodes until you scale it up]
  gpu -. tainted nvidia.com/gpu .-> pod[Only GPU pods that tolerate the taint land here]
```

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

## Remote state

State is a local file by default. `backend.tf.example` shows how to keep it in S3 with locking instead: create a versioned bucket, copy the file to `backend.tf`, fill in the bucket and region, and run `terraform init -migrate-state`. The lock uses `use_lockfile`, so there is no DynamoDB table, but it needs Terraform 1.11 or newer. I haven't run it against a real bucket, and it stays off unless you copy it.

## Cost

The pieces that bill while idle: the EKS control plane, the NAT gateway and the two system nodes. The GPU group costs nothing at 0. Run `terraform destroy` when you finish experimenting.

## If something doesn't work

Since I haven't applied this to a real account, these are the places I'd look first, based on how the code is set up.

- **`terraform plan` fails on `api_allowed_cidrs`.** The variable has no default, and the validation rejects an empty list and `0.0.0.0/0`. Put your own address in `terraform.tfvars`, for example `["203.0.113.7/32"]`.
- **`kubectl` can't reach the cluster.** The public API only accepts the addresses in `api_allowed_cidrs`. If your IP changed since the last apply, update the list and apply again.
- **The `gpu-test` pod stays Pending.** The GPU group starts at 0 and nothing in this repo scales it up by itself, so a pending GPU pod won't start a node. Raise the desired size first (see "Turning a GPU on and off") and give the node a few minutes to join.
- **The pod is scheduled but `nvidia.com/gpu` is missing from the node.** The NVIDIA device plugin isn't installed. Run the `kubectl apply` line from "Use it" and check again.
- **The GPU node never appears.** Spot capacity for the instance type may be short in your region, or your account's vCPU quota for G instances may be too low. Try `gpu_capacity_type = "ON_DEMAND"` or another entry in `gpu_instance_types`, and check the quotas in the AWS console.
- **The pod won't schedule on the system nodes.** That's the taint working. Only pods that tolerate `nvidia.com/gpu` and ask for the `workload: gpu` label can use the GPU group, which is what `k8s/gpu-test.yaml` does.

## CI

Each push runs `terraform fmt -check`, `terraform init` and `validate`, tflint, a Trivy config scan, and a kubeconform check on the test pod.

## Scan exceptions

Three Trivy findings are ignored in `.trivyignore`, each with the reason next to it: the public API endpoint (limited to your IP), open outbound traffic from worker nodes (needed to pull images), and the VPC module's default network ACLs (security groups do the filtering).

## What I'd do next

- Apply it once to a throwaway AWS account, fix whatever the first real run turns up, and then change the "not applied" note at the top.
- Add Karpenter in place of a fixed GPU node group, so nodes start when a GPU pod is pending and go away when it finishes.
- Install the NVIDIA device plugin from Terraform with a Helm release, so there is one less manual step after `apply`.
- Move to one NAT gateway per zone and say in the README what that adds to the idle cost.

## License

MIT
