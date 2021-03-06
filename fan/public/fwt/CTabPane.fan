using gfx
using fwt

// TODO: add showMinimised / showMaximised and associated events - but there's no EventId for it.
** (Widget) - 
** A container for 'CTabs' and a replacement for FWT [Tabs]`fwt::TabPane`. 
** 
** 'CTabs' follow Eclipse's *Custom* range of widgets. They are similar to normal tabs, except they:
** 
**  - have close buttons
**  - may be curved
**  - may be aligned on the bottom 
** 
** ![CTabs]`ctabs.png`
** 
** ![CTabs]`http://www.javalobby.org/images/postings/rj/fancy_tabs/5.gif`
** 
** See the [Fancy SWT Tabs]`http://www.javalobby.org/java/forums/t16488.html` article for details.
** 
** See [CTabFolder]`http://help.eclipse.org/indigo/topic/org.eclipse.platform.doc.isv/reference/api/org/eclipse/swt/custom/CTabFolder.html` SWT Widget.
@Serializable { collection = true }
class CTabPane : Pane {

	** Set to 'true' to create simple, non-curved, tabs.
	Bool simpleTabs	:= false
	
	** Where the tabs should be placed. Allowed values:
	**  - 'Valign.top'
	**  - 'Valign.bottom'
	Valign tabsValign	:= Valign.top {
		set { if (it != Valign.top && it != Valign.bottom) throw ArgErr("Only Valign.top and Valign.bottom allowed - $it"); &tabsValign = it }
	}
	
	** Callback when a tab is selected.
	**
	** Event id fired:
	**	 - 'EventId.select'
	**
	** Event fields:
	**	 - 'Event.index': index of selected tab
	**	 - 'Event.data': new active Tab instance
	once EventListeners onSelect() { EventListeners() }

	** Callback when a tab is closed.
	once EventListeners onClose() { EventListeners() }

	** Get the list of installed tabs.	Tabs are added and
	** removed using normal 'Widget.add' and 'Widget.remove'.
	CTab[] tabs() { return CTab[,].addAll(children) }

	** The currently selected index of `tabs`.
	@Transient
	native Int? selectedIndex

	** The currently selected tab.
	@Transient
	CTab? selected {
		get { i := selectedIndex; return i == null ? null : tabs[i] }
		set { i := index(it); if (i != null) selectedIndex = i }
	}

	** Get the index of the specified tab.
	Int? index(CTab tab) { return tabs.index(tab) }

	** Only `CTab` children may be added.
	@Operator
	override This add(Widget? kid) {
		if (kid isnot CTab)
			throw ArgErr("Child of CTabPane must be CTab, not ${Type.of(kid)}")
		super.add(kid)
		return this
	}
	
	@NoDoc	// required by Pane
	override Size prefSize(Hints hints := Hints.defVal) { Size(100,100) }

	@NoDoc	// required by Pane
	override Void onLayout() {}
}