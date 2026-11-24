# Kubernetes Context for Omarchy

Show and switch the current Kubernetes context from the right side of your Omarchy bar. Click the widget and choose a context. You can also use the arrow keys and Enter. The picker marks the current context, and the bar updates after a switch. Hover over the bar label to see the full context name.

## Requirements

- Omarchy 4.5, tested on 4.5.0-3
- `kubectl`, available on the Omarchy shell's `PATH`
- Bash and GNU coreutils (`timeout` and `head`), included with Omarchy

## Install

```sh
omarchy plugin add https://github.com/GregSharpe1/omarchy-kube-context.git --enable
```

The widget uses the desktop session's `KUBECONFIG` or the standard `~/.kube/config`. It reads context names from local kubeconfig every five seconds. Choosing a context runs `kubectl config use-context` to set `current-context` in that configuration. These commands run locally without contacting a cluster. A terminal using a different `KUBECONFIG` will have its own default.

If you keep your kubeconfig at a custom path, you can configure a fallback for when the desktop session has no `KUBECONFIG` and the standard path is absent.

```sh
omarchy bar set io.github.gregsharpe1.kube-context fallbackKubeconfig "$HOME/.kube/work.yaml"
```

The bar shows **No context** if no context is selected, or **Unavailable** if it cannot read the configuration.

## Remove

```sh
omarchy plugin remove io.github.gregsharpe1.kube-context
```

## License

MIT. See [LICENSE](LICENSE).
