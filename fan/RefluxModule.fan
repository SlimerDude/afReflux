using afIoc
using gfx
using fwt

** The IoC Module definition for Reflux.
@Js
const class RefluxModule {
	
	static Void defineServices(RegistryBuilder defs) {
		defs.addScope("uiThread", true)

		// Home made proxies
		defs.addService(Reflux#, RefluxProxy#)	.withScope("uiThread")
		defs.addService(RefluxImpl#)			.withScope("uiThread")
		
		// Home made proxies
		defs.addService(Errors#, ErrorsProxy#)	.withScope("uiThread")
		defs.addService(ErrorsImpl#)			.withScope("uiThread")

		defs.addService(Images#)				.withScope("uiThread")
		defs.addService(Preferences#)			.withScope("uiThread")
		defs.addService(EventHub#)				.withScope("uiThread")
		defs.addService(EventTypes#)
		defs.addService(Panels#)				.withScope("uiThread")
		defs.addService(UriResolvers#)			.withScope("uiThread")
		defs.addService(LocaleFormat#)			.withScope("uiThread")
		defs.addService(RefluxIcons#)			.withScope("uiThread")
		defs.addService(GlobalCommands#)		.withScope("uiThread")
		defs.addService(History#)				.withScope("uiThread")
		defs.addService(Session#)				.withScope("uiThread").withCtorArgs(["sessionData.fog"])
		defs.addService(Dialogues#)				.withScope("uiThread")
		
		defs.addService(RefluxEvents#)			.withScope("uiThread")
		
		defs.onScopeDestroy("uiThread") |config| {
			config["afReflux.disposeOfImages"] = |Scope scope| {
				imgSrc := (Images) scope.serviceByType(Images#)
				imgSrc.disposeAll
			}			
		}
	}
	
	@Contribute { serviceType=Panels# }
	static Void contributePanels(Configuration config) {
		config.add(config.build(ErrorsPanel#))
	}

	@Contribute { serviceType=RefluxIcons# }
	static Void contributeRefluxIcons(Configuration config) {
		EclipseIcons.iconMap.each |uri, id| {
			config[id] = uri.isAbs || uri.toStr.isEmpty ? uri : `fan://afReflux/res/icons-eclipse/` + uri
		}
	}

	@Contribute { serviceType=EventTypes# }
	static Void contributeEventHub(Configuration config) {
		config["afReflux.reflux"] = RefluxEvents#
	}

	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config) {
		// Plastic and dynamic compiling not available in JS
		if (Env.cur.runtime != "js") {
			eventProvider := config.build(EventProvider#)
			config["afReflux.eventProvider"] = eventProvider
		}
	}

	@Contribute { serviceType=GlobalCommands# }
	static Void contributeGlobalCommands(Configuration config) {
		config["afReflux.cmdNew"]			= config.build(GlobalCommand#, ["afReflux.cmdNew"])
		config["afReflux.cmdSave"]			= config.build(SaveCommand#)
		config["afReflux.cmdSaveAs"]		= config.build(GlobalCommand#, ["afReflux.cmdSaveAs"])
		config["afReflux.cmdSaveAll"]		= config.build(SaveAllCommand#)
		config["afReflux.cmdExit"]			= config.build(ExitCommand#)
		config["afReflux.cmdAbout"]			= config.build(AboutCommand#)
		config["afReflux.cmdRefresh"]		= config.build(RefreshCommand#)
		
		config["afReflux.cmdCut"]			= config.build(GlobalCommand#, ["afReflux.cmdCut"])
		config["afReflux.cmdCopy"]			= config.build(GlobalCommand#, ["afReflux.cmdCopy"])
		config["afReflux.cmdPaste"]			= config.build(GlobalCommand#, ["afReflux.cmdPaste"])

		config["afReflux.cmdNavUp"]			= config.build(NavUpCommand#)
		config["afReflux.cmdNavHome"]		= config.build(NavHomeCommand#)
		config["afReflux.cmdNavBackward"]	= config.build(NavBackwardCommand#)
		config["afReflux.cmdNavForward"]	= config.build(NavForwardCommand#)
		config["afReflux.cmdNavClear"]		= config.build(NavClearCommand#)

		config["afReflux.cmdToggleView"]	= config.build(ToggleViewCommand#)

		config["afReflux.cmdUndo"]			= config.build(UndoCommand#)
		config["afReflux.cmdRedo"]			= config.build(RedoCommand#)
	}
	


	// ---- Reflux Menu Bar -----------------------------------------------------------------------
	
	@Build { serviceId="afReflux.menuBar" }
	static Menu buildMenuBar(MenuItem[] menuItems) {
		Menu() { it.text="Menu" }.addAll(menuItems)
	}

	@Build { serviceId="afReflux.fileMenu" }
	static Menu buildFileMenu(MenuItem[] menuItems) {
		menu("afReflux.fileMenu").addAll(menuItems)
	}

	@Build { serviceId="afReflux.editMenu" }
	static Menu buildEditMenu(MenuItem[] menuItems) {
		menu("afReflux.editMenu").addAll(menuItems)
	}

	@Build { serviceId="afReflux.viewMenu" }
	static Menu buildViewMenu(MenuItem[] menuItems) {
		menu("afReflux.viewMenu").addAll(menuItems)	 
	}

	@Build { serviceId="afReflux.historyMenu" }
	static Menu buildHistoryMenu(MenuItem[] menuItems) {
		menu("afReflux.historyMenu").addAll(menuItems)
	}

	@Build { serviceId="afReflux.prefsMenu" }
	static Menu buildPrefsMenu(MenuItem[] menuItems) {
		menu("afReflux.preferencesMenu").addAll(menuItems)
	}

	@Build { serviceId="afReflux.helpMenu" }
	static Menu buildHelpMenu(MenuItem[] menuItems) {
		menu("afReflux.helpMenu").addAll(menuItems)
	}

	@Contribute { serviceId="afReflux.menuBar" }
	static Void contributeMenuBar(Configuration config) {
		addNonEmptyMenu(config, "afReflux.fileMenu")
		addNonEmptyMenu(config, "afReflux.editMenu")
		addNonEmptyMenu(config, "afReflux.viewMenu")
		addNonEmptyMenu(config, "afReflux.historyMenu")
		addNonEmptyMenu(config, "afReflux.prefsMenu")
		addNonEmptyMenu(config, "afReflux.helpMenu")
	}
	
	private static Void addNonEmptyMenu(Configuration config, Str menuId) {
		menu := (Menu) config.scope.serviceById(menuId)
		if (!menu.children.isEmpty)
			config[menuId] = menu
	}

	@Contribute { serviceId="afReflux.fileMenu" }
	static Void contributeFileMenu(Configuration config, GlobalCommands globalCmds) {
		config["afReflux.cmdNew"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdNew"].command)
		config["afReflux.separator01"]	= MenuItem { it.mode = MenuItemMode.sep }
		config["afReflux.cmdSave"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdSave"].command)
		config["afReflux.cmdSaveAs"]	= MenuItem.makeCommand(globalCmds["afReflux.cmdSaveAs"].command)
		config["afReflux.cmdSaveAll"]	= MenuItem.makeCommand(globalCmds["afReflux.cmdSaveAll"].command)
		config.addPlaceholder("afReflux.menuPlaceholder01")
		config.addPlaceholder("afReflux.menuPlaceholder02")
		config["afReflux.separator02"]	= MenuItem { it.mode = MenuItemMode.sep }
		config["afReflux.cmdExit"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdExit"].command)
	}

	@Contribute { serviceId="afReflux.editMenu" }
	static Void contributeEditMenu(Configuration config, GlobalCommands globalCmds) {
		config["afReflux.cmdUndo"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdUndo"].command)
		config["afReflux.cmdRedo"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdRedo"].command)
		config["afReflux.separator01"]	= MenuItem { it.mode = MenuItemMode.sep }
		config["afReflux.cmdCut"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdCut"].command)
		config["afReflux.cmdCopy"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdCopy"].command)
		config["afReflux.cmdPaste"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdPaste"].command)
		config.addPlaceholder("afReflux.menuPlaceholder01")
		config.addPlaceholder("afReflux.menuPlaceholder02")
	}

	@Contribute { serviceId="afReflux.viewMenu" }
	static Void contributeViewMenu(Configuration config, Panels panels, GlobalCommands globalCmds) {
		
		// only stick panels in a sub-menu should there be a few of them
		if (panels.panels.size > 5) {   
			panelsMenu := menu("afReflux.showPanelMenu")
			panels.panels.each {
				cmd := config.build(ShowHidePanelCommand#, [it])
				panelsMenu.add(MenuItem.makeCommand(cmd))
			}
			config["afReflux.panelMenu"] = panelsMenu

		} else {
			panels.panels.each {
				cmd := config.build(ShowHidePanelCommand#, [it])
				config.add(MenuItem.makeCommand(cmd))
			}	
		}

		config.addPlaceholder("afReflux.menuPlaceholder01")
		config.addPlaceholder("afReflux.menuPlaceholder02")
		config["afReflux.separator01"]		= MenuItem { it.mode = MenuItemMode.sep }
		config["afReflux.cmdRefresh"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdRefresh"].command)
		config["afReflux.cmdToggleView"]	= MenuItem.makeCommand(globalCmds["afReflux.cmdToggleView"].command)
	}

	@Contribute { serviceId="afReflux.historyMenu" }
	static Void contributeHistoryMenu(Configuration config, GlobalCommands globalCmds) {
		config["afReflux.cmdNavBackward"]	= MenuItem.makeCommand(globalCmds["afReflux.cmdNavBackward"].command)
		config["afReflux.cmdNavForward"]	= MenuItem.makeCommand(globalCmds["afReflux.cmdNavForward"].command)
		config["afReflux.cmdNavUp"]			= MenuItem.makeCommand(globalCmds["afReflux.cmdNavUp"].command)
		config["afReflux.cmdNavHome"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdNavHome"].command)
		config["afReflux.separator01"]		= MenuItem { it.mode = MenuItemMode.sep }
		config["afReflux.cmdNavClear"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdNavClear"].command)
		config.addPlaceholder("afReflux.menuPlaceholder01")
		config.addPlaceholder("afReflux.menuPlaceholder02")
	}

	@Contribute { serviceId="afReflux.PrefsMenu" }
	static Void contributePrefsMenu(Configuration config, GlobalCommands globalCmds) {
		config.addPlaceholder("afReflux.menuPlaceholder01")
		config.addPlaceholder("afReflux.menuPlaceholder02")
	}

	@Contribute { serviceId="afReflux.helpMenu" }
	static Void contributeHelpMenu(Configuration config, GlobalCommands globalCmds) {
		config.addPlaceholder("afReflux.menuPlaceholder01")
		config.addPlaceholder("afReflux.menuPlaceholder02")
		config["afReflux.cmdAbout"]			= MenuItem.makeCommand(globalCmds["afReflux.cmdAbout"].command)
	}
	


	// ---- Reflux Tool Bar -----------------------------------------------------------------------

	@Build { serviceId="afReflux.toolBar" }
	static ToolBar buildToolBar(Widget[] toolBarItems) {
		ToolBar().addAll(toolBarItems)
	}

	@Contribute { serviceId="afReflux.toolBar" }
	static Void contributeToolBar(Configuration config, GlobalCommands globalCmds) {
		config["afReflux.cmdSave"]			= toolBarCommand(globalCmds["afReflux.cmdSave"].command)
		config["afReflux.cmdSaveAll"]		= toolBarCommand(globalCmds["afReflux.cmdSaveAll"].command)
		config["afReflux.separator01"]		= Button { mode = ButtonMode.sep }
		config["afReflux.cmdNavBackward"]	= toolBarCommand(globalCmds["afReflux.cmdNavBackward"].command)
		config["afReflux.cmdNavForward"]	= toolBarCommand(globalCmds["afReflux.cmdNavForward"].command)
		config["afReflux.cmdNavUp"]			= toolBarCommand(globalCmds["afReflux.cmdNavUp"].command)
		config["afReflux.cmdRefresh"]		= toolBarCommand(globalCmds["afReflux.cmdRefresh"].command)
		config["afReflux.uriWidget"]		= Env.cur.runtime == "js" ? config.build(UriWidgetJs#) : config.build(UriWidget#)
		config["afReflux.cmdNavHome"]		= toolBarCommand(globalCmds["afReflux.cmdNavHome"].command)
	}



	// ---- Private Methods -----------------------------------------------------------------------

	private static Menu menu(Str menuId) {
		Menu() {
			// TODO: localise using id
			if (menuId.startsWith("afReflux."))
				menuId = menuId["afReflux.".size..-1]
			if (menuId.endsWith("Menu"))
				menuId = menuId[0..<-"Menu".size]
			it.text = menuId.toDisplayName
		}
	}

	private static Button toolBarCommand(Command command) {
		button  := Button.makeCommand(command)
		if (command.icon != null)
			button.text = ""
		return button
	}
}