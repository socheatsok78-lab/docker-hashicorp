## About

<br />
<img src="./.github/assets/consul.svg" height="32px" />&nbsp;&nbsp;
<img src="./.github/assets/vault.png" height="32px" />&nbsp;&nbsp;
<img src="./.github/assets/openbao.png" height="32px" />&nbsp;&nbsp;

A collections of custom built HashiCorp container images with a customized service discovery mechanism.

This project integrates `hashicorp/go-netaddrs` as a discovery provider. It achieves this by substituting the default `github.com/hashicorp/go-discover` with a tailored fork, `github.com/socheatsok78-lab/go-discover`, available [here](https://github.com/socheatsok78-lab/go-discover/tree/go-netaddrs).
