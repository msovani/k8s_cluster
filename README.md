# k8s_cluster
This repo contains Terraform code that sets up k8s cluster using Terraform

### Basic Unix Aliases/ Exports

Kubectl alias should already be set. if not, set it up like this.
```
alias k=kubectl
```

Set export for Dry run and now
```
export DR="-o yaml --dry-run=client"
export now='--grace-period=0 --force'

```

Set export for etcd api version
```
export ETCDCTL_API=3
```

create .vimrc file and add following line in it.
```
se nu ts=2 sw=2 sts=2 et cul cuc ai
```

1. nu = line numbers
1. ts = tab stop of 2
1. sw = shift width of 2
1. sts = soft tab stop
1. et = expand tab
1. ai = auto indent
1. cul = current line 
1. cuc = current column