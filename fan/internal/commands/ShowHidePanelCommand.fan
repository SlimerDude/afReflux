using afIoc
using fwt

internal class ShowHidePanelCommand : RefluxCommand, RefluxEvents {
	@Inject private Registry	reg
	@Inject private Reflux		reflux
			private Panel 		panel

	new make(Panel panel, |This|in) : super.make(in) {
		this.panel = panel
		this.mode = CommandMode.toggle
		onPanelModified(panel)
	}

	override Void doInvoke(Event? event) {
		if (panel.isShowing) reflux.hidePanel(panel.typeof); else reflux.showPanel(panel.typeof)
	}

	override Void onPanelModified(Panel panel) {
		if (this.panel == panel) {
			this.name 		= panel.name
			this.icon		= panel.icon
			this.selected	= panel.isShowing
		}
	}
}