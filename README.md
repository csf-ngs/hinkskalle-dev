# hinkskalle-dev

[![Build Status](https://knecht.testha.se/api/badges/csf-ngs/hinkskalle-dev/status.svg)](https://knecht.testha.se/csf-ngs/hinkskalle-dev)

dev + test container for Hinkskalle

Complete development environment for Hinkskalle, including:

- python
- flask
- node.js + vue-cli
- singularity

This container is meant to be run in the root of the Hinkskalle repo.

**Note** patched version singularity.dev is gone in 3.0.0, use `--insecure` and `--no-https`
flags instead.
