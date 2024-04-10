# Buildbarn deployment for Kubernetes with mTLS

This directory accompanies the blog post about deploying Buildbarn on
Kubernetes with mTLS: https://www.tweag.io/blog/2024-02-01-buildbarn-mtls.
If you would like to follow step by step instructions with all explanations,
please follow the blog post.

To replicate results from the blog post, you can:

- run `./deploy.sh` to create lima VM with Kubernetes and deploy Buildbarn with
  mTLS configured for it
- in `example` directory you can find one of the examples from upstream Bazel
  [repo](https://github.com/bazelbuild/examples/tree/main/cpp-tutorial/stage1)
  adapted to use Buildbarn with current setup
- there you can run `./get-certificates.sh` to generate necessary certificates,
  and then `bazel build //main:hello-world` to build the project
