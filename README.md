# Kubernetes Context for Omarchy

Show the current Kubernetes context on the right side of your Omarchy bar. The widget reads local kubeconfig every five seconds. Hover over it to see the full context name if the bar label is shortened.

## Requirements

- Omarchy 4.5, tested on 4.5.0-3
- `kubectl`, available on the Omarchy shell's `PATH`
- Bash and GNU coreutils (`timeout` and `head`), included with Omarchy

## Install

```sh
omarchy plugin add https://github.com/GregSharpe1/omarchy-kube-context.git --enable
```

The widget uses the desktop session's `KUBECONFIG` or the standard `~/.kube/config`. It reads only the selected context name for display. The check runs locally and leaves the kubeconfig untouched.

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
