import QtQuick
import Quickshell.Io
import qs.Commons as Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
  moduleName: "io.github.gregsharpe1.kube-context"

  readonly property string fallbackKubeconfig: String(setting("fallbackKubeconfig", ""))
  property string contextName: ""
  property string status: "loading"

  readonly property string labelText: strings.t("bar.label").arg(contextName || strings.t("bar." + status))

  function refresh() {
    if (!query.running)
      query.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onFallbackKubeconfigChanged: refresh()
  Component.onCompleted: refresh()

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: query
    command: ["bash", decodeURIComponent(Qt.resolvedUrl("read-context").toString().replace(/^file:\/\//, "")),
      root.fallbackKubeconfig]
    stdout: StdioCollector { id: contextOutput }
    onExited: function(exitCode, exitStatus) {
      const output = contextOutput.text
      const usable = exitCode === 0 && exitStatus === 0 && contextOutput.data.byteLength <= 1024
      // Keep each context on one line and neutralize control characters.
      root.contextName = usable ? output.replace(/[\x00-\x1f\x7f-\x9f\u2028-\u202e\u2066-\u2069]/g, "�") : ""
      root.status = usable ? "unset" : "error"
    }
  }

  TextMetrics {
    id: labelMetrics
    text: root.labelText
    font.family: button.fontFamily
    font.pixelSize: button.fontSize
    elide: Qt.ElideMiddle
    elideWidth: Commons.Style.space(185)
  }

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical ? strings.t("bar.vertical") : labelMetrics.elidedText
    tooltipText: root.contextName
      ? strings.t("tooltip.context").arg(root.contextName)
      : strings.t("tooltip." + root.status)
    pressable: false
  }
}
