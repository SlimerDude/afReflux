using afIoc
using afIocConfig
using afConcurrent
using gfx
using fwt

@NoDoc
@SubModule { modules=[FileExplorerModule#] }
class RefluxModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(Reflux#).withProxy
		defs.add(Errors#).withProxy

		defs.add(ImageSource#)
		defs.add(PrefsCache#)
		defs.add(EventHub#)
		defs.add(EventTypes#)
		defs.add(Panels#)
		defs.add(UriResolvers#)
		defs.add(LocaleFormat#)
		defs.add(RefluxIcons#, EclipseIcons#)

		defs.add(GlobalCommands#)
	}
	
	@Contribute { serviceType=Panels# }
	static Void contributePanels(Configuration config) {
		config.add(config.autobuild(ErrorsPanel#))
	}

	@Contribute { serviceType=EventTypes# }
	static Void contributeEventHub(Configuration config) {
		config["afReflux.reflux"] = RefluxEvents#
	}

	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config) {
		eventProvider := config.autobuild(EventProvider#)
		config.set("afReflux.eventProvider", eventProvider).before("afIoc.serviceProvider")
	}

	@Contribute { serviceType=GlobalCommands# }
	static Void contributeGlobalCommands(Configuration config) {
		config["afReflux.cmdAbout"]		= config.autobuild(AboutCommand#)
		config["afReflux.cmdExit"]		= config.autobuild(ExitCommand#)
		config["afReflux.cmdParent"]	= config.autobuild(ParentCommand#)
		config["afReflux.cmdRefresh"]	= config.autobuild(RefreshCommand#)
	}

	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(Configuration config) {
		config[RefluxConfigIds.appTitle]	= "Reflux"
		config[RefluxConfigIds.appIcon]		= `fan://icons/x32/flux.png`		
	}

	@Contribute { serviceType=RegistryShutdown# }
	internal static Void contributeRegistryShutdown(Configuration config, Registry registry) {
		config["afReflux.disposeOfImages"] = |->| {
			imgSrc := (ImageSource) registry.dependencyByType(ImageSource#)
			imgSrc.disposeOfImages
		}
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

	@Build { serviceId="afReflux.optionsMenu" }
	static Menu buildOptionsMenu(MenuItem[] menuItems) {
		menu("afReflux.optionsMenu").addAll(menuItems)
	}

	@Build { serviceId="afReflux.panelMenu" }
	static Menu buildPanelMenu(MenuItem[] menuItems, Panels panels) {
		menu := menu("afReflux.panelMenu")
		
		panels.panels.each { 
			menu.add(MenuItem.makeCommand(it.showHideCommand))
		}
		
		if (!menuItems.isEmpty) {
			menu.addSep
			menu.addAll(menuItems)
		}
		return menu
	}

	@Build { serviceId="afReflux.helpMenu" }
	static Menu buildHelpMenu(MenuItem[] menuItems) {
		menu("afReflux.helpMenu").addAll(menuItems)
	}

	@Contribute { serviceId="afReflux.menuBar" }
	static Void contributeMenuBar(Configuration config, Registry reg) {
		// TODO: only add menus if they have children
		config["afReflux.fileMenu"]		= reg.serviceById("afReflux.fileMenu")
//		config["editMenu"]	= reg.serviceById("afReflux.editMenu")
		config["afReflux.optionsMenu"]	= reg.serviceById("afReflux.optionsMenu")
		config["afReflux.panelMenu"]	= reg.serviceById("afReflux.panelMenu")
		config["afReflux.helpMenu"]		= reg.serviceById("afReflux.helpMenu")
	}

	@Contribute { serviceId="afReflux.fileMenu" }
	static Void contributeFileMenu(Configuration config, GlobalCommands globalCmds) {
		config["afReflux.exit"]		= MenuItem.makeCommand(globalCmds["afReflux.cmdExit"].command)
	}

	@Contribute { serviceId="afReflux.helpMenu" }
	static Void contributeHelpMenu(Configuration config, GlobalCommands globalCmds) {
		config["afReflux.about"]	= MenuItem.makeCommand(globalCmds["afReflux.cmdAbout"].command)
	}

	
	
	// ---- Reflux Tool Bar -----------------------------------------------------------------------

	@Build { serviceId="afReflux.toolBar" }
	static ToolBar buildToolBar(Widget[] toolBarItems) {
		ToolBar().addAll(toolBarItems)
	}

	@Contribute { serviceId="afReflux.toolBar" }
	static Void contributeToolBar(Configuration config, GlobalCommands globalCmds) {
		config["afReflux.refresh"]		= toolBarCommand(globalCmds["afReflux.cmdRefresh"].command)
		config["afReflux.uriWidget"]	= config.autobuild(UriWidget#)
		config["afReflux.parent"]		= toolBarCommand(globalCmds["afReflux.cmdParent"].command)
	}
	
	
	
	// ---- Private Methods -----------------------------------------------------------------------

	private static Menu menu(Str menuId) {
		Menu() {
			if (menuId.startsWith("afReflux."))
				menuId = menuId["afReflux.".size..-1]
			if (menuId.endsWith("Menu"))
				menuId = menuId[0..<-"Menu".size]
			it.text = menuId.toDisplayName
		}
	}

	@Deprecated
	private static MenuItem menuCommand(Configuration config, Type cmdType) {
		MenuItem.makeCommand(config.autobuild(cmdType))
	}

	private static Button toolBarCommand(Command command) {
	    button  := Button.makeCommand(command)
	    if (command.icon != null)
	    	button.text = ""
		return button
	}
}
