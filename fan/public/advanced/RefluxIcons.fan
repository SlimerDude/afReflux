using afIoc
using gfx

@NoDoc	// Advanced use only!
class RefluxIcons {
	@Inject private const Log	log
	@Inject private Images		images
			private Str:Uri		iconMap
	
	new make(Str:Uri iconMap, |This| in) {
		in(this)
		this.iconMap = iconMap
	}
	
	@Operator
	virtual Image? get(Str name) {
		icon(name, false)
	}
	
	Image? icon(Str name, Bool faded) {
		if (!iconMap.containsKey(name)) {
			log.warn("No icon for : $name")
			return null
		}

		uri := iconMap[name]
		if (uri.toStr.isEmpty)
			return null

		return images.get(uri, faded)
	}
	
	Image? fromUri(Uri? icoUri, Bool faded := false, Bool checked := true) {
		images.get(icoUri, faded, checked)
	}
}

@NoDoc
internal class EclipseIcons {
	static const Str:Uri iconMap := [
		"cmdExit"				: ``,
		"cmdAbout"				: `fan://icons/x16/flux.png`,
		"cmdRefresh"			: `nav_refresh.gif`,
		"cmdParent"				: `up_nav.gif`,

		"cmdSave"				: `save_edit.gif`,
		"cmdSaveAs"				: `saveas_edit.gif`,
		"cmdSaveAll"			: `saveall_edit.gif`,

		"cmdFind"				: ``,
		"cmdFindPrev"			: `nav_backward.gif`,
		"cmdFindNext"			: `nav_forward.gif`,
		"cmdReplace"			: ``,
		"cmdGoto"				: ``,
		
		"icoErrorsPanel"		: `error_log.gif`
	]
}
