using afIoc
using gfx
using fwt

@Js
internal class Frame : Window, RefluxEvents {

	private Obj:PanelTabPane	panelTabs	:= [:]
	private ViewTabPane			viewTabs
	private Bool				closing
	private Str					appName
	private SashPane			sash1
	private SashPane			sash2

	internal new make(Reflux reflux, Scope scope, RegistryMeta regMeta) : super() {
		this.appName= regMeta[RefluxConstants.meta_appName]
		this.title	= regMeta[RefluxConstants.meta_appName]
		this.icon	= Image(`fan://icons/x32/flux.png`)
		this.size	= Size(640, 480)

		eventHub	:= (EventHub) scope.serviceById(EventHub#.qname)
		eventHub.register(this)

		panelTabs[Halign.left]	= scope.build(PanelTabPane#, [false, false])
		panelTabs[Halign.right]	= scope.build(PanelTabPane#, [false, false])
		panelTabs[Valign.bottom]= scope.build(PanelTabPane#, [false, true])
		viewTabs				= scope.build(ViewTabPane#,  [reflux])

		navBar := (RefluxBar) scope.build(RefluxBar#)

		// see http://fantom.org/forum/topic/2324
		if (Env.cur.runtime != "js")
			this.menuBar	= scope.serviceById("afReflux.menuBar")

		this.content = EdgePane {
			top = navBar
			center = sash1 = SashPane {
				it.orientation = Orientation.horizontal
				it.weights = [25, 50, 25]
				panelTabs[Halign.left],
				sash2 = SashPane {
					it.orientation = Orientation.vertical
					it.weights = [70, 30]
					viewTabs,
					panelTabs[Valign.bottom],
				},
				panelTabs[Halign.right],
			}
		}
		refreshSashPanes()

		this.onClose.add |Event e| { if (!closing) reflux.exit }

		// Handle file drops -> open up FWT's back door!
		dialogues := (Dialogues) scope.serviceById(Dialogues#.qname)
		this.onDrop = |Obj data| {
			files 	:= (File[]) data
			handled := reflux.activeView?.onDrop(files) ?: false
			if (!handled) {
				if (files.size > 10) {
					answer := dialogues.openQuestion("Do you really want to open ${files.size} files?", null, dialogues.yesNo)
					if (answer == dialogues.yes)
						files.each { reflux.load(it.normalize.uri.toStr, LoadCtx { it.newTab = true }) }
				} else
					files.each { reflux.load(it.normalize.uri.toStr, LoadCtx { it.newTab = true }) }
			}
		}
	}

	View[] dirtyViews() {
		viewTabs.dirtyViews
	}

	Void activateView(View view) {
		viewTabs.activate(view)
	}

	Void showPanel(Panel panel, Obj prefAlign) {
		panelTabs[prefAlign].addTab(panel).activate(panel)
		refreshSashPanes()
	}

	Void activatePanel(Panel panel, Obj prefAlign) {
		panelTabs[prefAlign].activate(panel)
	}

	Void hidePanel(Panel panel, Obj prefAlign) {
		panelTabs[prefAlign].activate(null).removeTab(panel)
	}

	View? replaceView(View view, Type viewType) {
		viewTabs.replaceView(view, viewType)
	}

	Bool closeView(View view, Bool force) {
		viewTabs.closeView(view, force)
	}

	View? load(Resource resource, LoadCtx ctx) {
		view := viewTabs.load(resource, ctx)
		update(view, resource, false)
		return view
	}
	
	Void refreshViews(Resource? resource) {
		viewTabs.panels.each { it.refresh(resource) }
	}

	override Void onViewActivated(View view) {
		update(view, view.resource, view.isDirty)
	}

	override Void onViewModified(View view) {
		update(view, view.resource, view.isDirty)
	}

	override Void onLoadSession(Str:Obj? session) {
		sash1.weights = session["afReflux.frame.sash1Weights"] ?: sash1.weights
		sash2.weights = session["afReflux.frame.sash2Weights"] ?: sash2.weights
	}

	override Void onSaveSession(Str:Obj? session) {
		session["afReflux.frame.sash1Weights"] = sash1.weights
		session["afReflux.frame.sash2Weights"] = sash2.weights
	}

	override Void close(Obj? result := null) {
		this.closing = true
		super.close(result)
	}

	private Void update(View? view, Resource? resource, Bool isDirty) {
		if (view == null || !view.isActive || resource == null)
			return
		this.title = "${appName} - ${resource.name}"
		if (isDirty)
			title += " *"
	}
	
	private Void refreshSashPanes() {
		// in JS, empty panes don't collapse so set their weight to zero 
		if (Env.cur.runtime == "js") {
			weights := [25, 50, 25]
			if (panelTabs[Halign.left].panelTabs.isEmpty) {
				weights[0] = 0
				weights[1] += 25
			}
			if (panelTabs[Halign.right].panelTabs.isEmpty) {
				weights[1] += 25
				weights[2] = 0
			}
			if (sash1.weights != weights)
				sash1.weights = weights
			
			weights = [70, 30]
			if (panelTabs[Valign.bottom].panelTabs.isEmpty) {
				weights[0] += 30
				weights[1] = 0
			}
			if (sash2.weights != weights)
				sash2.weights = weights
		}		
	}
}