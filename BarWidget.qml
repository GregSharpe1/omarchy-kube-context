import QtQuick
import QtQuick.Controls as Controls
import Quickshell.Io
import qs.Commons as Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
  moduleName: "io.github.gregsharpe1.kube-context"

  readonly property string fallbackKubeconfig: String(setting("fallbackKubeconfig", ""))
  readonly property string helperPath: decodeURIComponent(Qt.resolvedUrl("read-context").toString().replace(/^file:\/\//, ""))
  readonly property string contextName: displayName(currentContext)
  readonly property string labelText: strings.t("bar.label").arg(contextName || strings.t("bar." + status))
  property string currentContext: ""
  property var contexts: []
  property string status: "loading"
  property string pendingContext: ""
  property bool switchFailed: false
  property bool opened: false
  property bool popoutSwitchClosing: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!query.running && !pendingContext) query.running = true
  }

  function displayName(name) {
    return name.replace(/[\x00-\x1f\x7f-\x9f\u2028-\u202e\u2066-\u2069]/g, "�")
  }

  function open() {
    if (opened || !bar) return
    if (!pendingContext) switchFailed = false
    opened = true
    refresh()
    if (panel.loadedContent) panel.loadedContent.selectCurrent()
  }

  function close() { opened = false }

  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
    Qt.callLater(() => { root.popoutSwitchClosing = false })
  }

  function choose(name) {
    if (!name || name === currentContext || pendingContext || !contexts.includes(name)) return
    switchFailed = false
    pendingContext = name
    if (!query.running) switchContext.running = true
  }

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
    command: ["bash", root.helperPath, root.fallbackKubeconfig, "list"]
    stdout: StdioCollector { id: contextOutput }
    onExited: function(exitCode, exitStatus) {
      if (root.pendingContext) {
        switchContext.running = true
        return
      }
      if (exitCode === 0 && exitStatus === 0 && contextOutput.data.byteLength <= 262144) {
        try {
          // kubectl emits a JSON array for each expression, separated by a newline.
          const [current, names] = contextOutput.text.trim().split(/\r?\n(?=\[)/).map(part => JSON.parse(part))
          names.sort()
          root.currentContext = current[0] || ""
          if (JSON.stringify(root.contexts) !== JSON.stringify(names))
            root.contexts = names
          root.status = "unset"
          return
        } catch (error) {
          console.warn("Could not parse kubectl context list:", error.message)
        }
      }
      root.currentContext = ""
      root.contexts = []
      root.status = "error"
    }
  }

  Process {
    id: switchContext
    command: ["bash", root.helperPath, root.fallbackKubeconfig, "use", root.pendingContext]
    onExited: function(exitCode, exitStatus) {
      root.switchFailed = exitCode !== 0 || exitStatus !== 0
      root.pendingContext = ""
      Qt.callLater(root.refresh)
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
    tooltipText: root.opened ? "" : root.contextName
      ? strings.t("tooltip.context").arg(root.contextName)
      : strings.t("tooltip." + root.status)
    active: root.opened
    pressFeedbackButtons: Qt.LeftButton
    onPressed: function(mouseButton) {
      if (mouseButton !== Qt.LeftButton) return
      if (root.opened) root.close()
      else root.open()
    }
  }

  Ui.KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: loadedContent
    contentWidth: fittedContentWidth(Commons.Style.space(440))
    contentHeight: fittedContentHeight(loadedContentHeight, Commons.Style.space(400))

    content: FocusScope {
      id: picker
      implicitHeight: heading.height + notice.height + list.contentHeight + Commons.Style.space(8)

      function selectCurrent() {
        if (!list.count) return
        list.currentIndex = Math.max(0, root.contexts.indexOf(root.currentContext))
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
      }

      Component.onCompleted: selectCurrent()
      Keys.onEscapePressed: root.close()

      component PanelText: Text {
        textFormat: Text.PlainText
        color: Commons.Color.popups.text
        font.family: Commons.Style.font.menuFamily
        font.pixelSize: Commons.Style.font.body
      }

      PanelText {
        id: heading
        width: parent.width
        font.pixelSize: Commons.Style.font.heading
        text: strings.t("panel.title")
      }

      Item {
        id: notice
        anchors.top: heading.bottom
        anchors.topMargin: Commons.Style.space(8)
        width: parent.width
        height: message.text === "" ? 0 : message.implicitHeight + Commons.Style.space(4)

        PanelText {
          id: message
          width: parent.width
          wrapMode: Text.Wrap
          text: root.pendingContext ? strings.t("panel.switching")
            : root.switchFailed ? strings.t("panel.switchError")
            : root.status === "error" ? strings.t("tooltip.error")
            : root.status === "loading" ? strings.t("tooltip.loading")
            : root.contexts.length === 0 ? strings.t("panel.empty") : ""
        }
      }

      ListView {
        id: list
        anchors {
          top: notice.bottom
          bottom: parent.bottom
          left: parent.left
          right: parent.right
        }
        model: root.contexts
        clip: true
        focus: true
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: true
        onCountChanged: picker.selectCurrent()
        Keys.onReturnPressed: root.choose(root.contexts[currentIndex])
        Keys.onEnterPressed: root.choose(root.contexts[currentIndex])
        Keys.onSpacePressed: root.choose(root.contexts[currentIndex])

        Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }

        delegate: Rectangle {
          id: row
          required property string modelData
          required property int index
          readonly property bool current: modelData === root.currentContext
          width: ListView.view.width - Commons.Style.space(12)
          height: Commons.Style.space(34)
          radius: Commons.Style.cornerRadius
          color: mouse.containsMouse || (ListView.isCurrentItem && list.activeFocus)
            ? Commons.Util.alpha(Commons.Color.popups.text, 0.10) : "transparent"

          PanelText {
            anchors.left: parent.left
            anchors.right: badge.visible ? badge.left : parent.right
            anchors.margins: Commons.Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            font.bold: row.current
            elide: Text.ElideMiddle
            text: root.displayName(row.modelData)
          }

          PanelText {
            id: badge
            anchors.right: parent.right
            anchors.rightMargin: Commons.Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            visible: row.current
            text: strings.t("panel.current")
          }

          MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: !row.current && !root.pendingContext
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              list.currentIndex = row.index
              root.choose(row.modelData)
            }
          }
        }
      }
    }
  }
}
