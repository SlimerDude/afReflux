using afIoc
using gfx
using fwt

@Js
internal class PanelTabPane : ContentPane {
	Widget			tabPane
	PanelTabTuple[]	panelTabs	:= PanelTabTuple[,]	// 'cos I can't use non-const Panel as a key
	Bool			alwaysShowTabs	// TODO: implement alwaysShowTabs

	new make(Bool visible, Bool alwaysShowTabs, |This|in) {
		
		if (Env.cur.runtime == "js")
			tabPane	= TabPane() {
				it.onSelect.add |e| { this->onSelect(e) }
			}
		else {
			// see http://fantom.org/forum/topic/2501 for lack of it-block ctor usage
			ctab := (CTabPane) (tabPane = CTabPane())
			ctab.onSelect.add |e| { this->onSelect(e) }
			ctab.onClose.add  |e| { this->onClose (e) }
		}
		
		in(this)
		this.visible = visible
		this.alwaysShowTabs = alwaysShowTabs
	}

	This addTab(Panel panel) {
		if (panelTabs.find { it.panel === panel } != null)
			return this	// already added

		tuple := panelTabs.add(PanelTabTuple(panel, tabPane)).last
		panel._parentFunc = |->Widget| { tuple.tab ?: this }

		switch (panelTabs.size-1) {
			case 0:
				this.content = panel.content
				this.visible = true

			case 1:
				this.content = tabPane
				panelTabs.first.addToTabPane
				tuple.addToTabPane

			default:
				tuple.addToTabPane
		}

		this.parent.relayout
		this.relayout

		panel.isShowing = true
		panel->onShow

		return this
	}

	This removeTab(Panel panel) {
		tuple := panelTabs.find { it.panel === panel }
		if (tuple == null)
			return this

		activate(null)	// deactivate if its showing
		panel.isShowing = false
		panel->onHide

		panelTabs.removeSame(tuple)

		switch (panelTabs.size) {
			case 0:
				this.content = null
				this.visible = false

			case 1:
				tuple.removeFromTabPane
				panelTabs.first.removeFromTabPane
				this.content = panelTabs.first.panel.content

				// need to activate this ourselves because there's no TabPane select event
				activate(panelTabs.first.panel)

			default:
				tuple.removeFromTabPane
		}

		this.parent.relayout
		this.relayout
		return this
	}

	** Pass null to just deactivate
	This activate(Panel? panel) {
		tuple := panelTabs.find { it.panel === panel }

		panelTabs.each {
			if (it !== tuple && it.panel.isActive) {
				it.panel.isActive = false
				it.panel->onDeactivate
			}
		}

		if (tuple != null) {
			if (tuple.tab != null) {
				tabPane->selected = tuple.tab
				// see http://fantom.org/forum/topic/2459#c1
//				if (Env.cur.runtime == "js")
//					tabPane.relayout
			}

			if (tuple.panel.isActive == false) {
				tuple.panel.isActive = true
				tuple.panel->onActivate
			}
		}

		return this
	}

	Void onSelect(Event? event)	{
		selected := tabPane->selected

		if (selected != null) {
			tuple := panelTabs.find { it.tab === selected }
			if (tuple == null) return
			activate(tuple.panel)
		}
	}

	Void onClose(Event? event)	{
		tuple := panelTabs.find { it.tab === event.data }
		if (tuple?.panel != null) {

			if (tuple.panel is View && this is ViewTabPane) {

				if (((ViewTabPane) this).closeView(tuple.panel, false) == false)
					event.consume

			} else {
				removeTab(tuple.panel)
				// don't consume the event, so SWT fires a select event
				// event.consume
			}
		}
	}
	
	Panel[] panels() {
		panelTabs.map { it.panel }
	}
}

@Js
internal class PanelTabTuple {
	Widget		tabPane
	Panel		panel
	Widget?		tab

	new make(Panel panel, Widget tabPane) {
		this.tabPane = tabPane
		this.panel = panel
	}

	This addToTabPane() {
		tab	= Env.cur.runtime == "js" ? Tab() : CTab()
		tab.add(panel.content)
		tab->text  = panel.name
		if (panel.icon != null)	// JS dies if null
			tab->image = panel.icon
		tabPane.add(tab)
		return this
	}

	This removeFromTabPane() {
		tab.remove(panel.content)
		tabPane.remove(tab)
		tab = null
		return this
	}

	This swapPanel(Panel newPanel) {
		// there is no tab if it's the only panel
		tab?.remove(panel.content)

		panel = newPanel

		if (tab != null) {
			tab.add(newPanel.content)
			tab->text  = newPanel.name
			if (panel.icon != null)	// JS dies if null
				tab->image = newPanel.icon
		}

		return this
	}
}